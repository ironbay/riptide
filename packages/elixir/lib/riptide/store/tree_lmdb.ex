defmodule Riptide.Store.TreeLMDB do
  @behaviour Riptide.Store
  @delimiter "×"

  @impl true
  def init(opts) do
    directory = opts_directory(opts)
    {:ok, env} = Bridge.LMDB.open_env(directory)
    :persistent_term.put({:riptide_lmdb, directory}, env)

    :ok
  end

  @impl true
  def mutation(merges, deletes, opts) do
    tree = opts_tree(opts)
    env = env(opts)

    merges
    |> Stream.map(fn {path, val} ->
      branch = tree.for_path(path)
      {columns, extra} = Enum.split(path, Enum.count(branch.columns))

      {columns, extra, val}
    end)
    |> Enum.group_by(
      fn {columns, _path, _val} ->
        columns
      end,
      fn {_columns, path, val} ->
        {path, val}
      end
    )
    |> Stream.map(fn {columns, values} ->
      existing =
        env
        |> iterate(columns, %{})
        |> Enum.at(0)
        |> case do
          nil ->
            nil

          result ->
            Jason.decode!(result)
        end

      next =
        values
        |> Enum.reduce(existing, fn
          {[], val}, _collect ->
            val

          {path, val}, collect ->
            case collect do
              nil -> %{}
              result when is_map(result) -> result
              _ -> %{}
            end
            |> Dynamic.put(path, val)
        end)
    end)
  end

  def iterate(env, path, opts) do
    combined = encode_path(path)
    {min, max} = Riptide.Store.Prefix.range(combined, opts)
    min = Enum.join(min, @delimiter)
    max = Enum.join(max, @delimiter)

    {:ok, tx} = Bridge.LMDB.txn_read_new(env)

    exact =
      tx
      |> Bridge.LMDB.get(min)
      |> case do
        {:ok, value} -> [{min, value}]
        _ -> []
      end

    :ok = Bridge.LMDB.txn_read_abort(tx)

    Stream.concat(
      exact,
      Bridge.LMDB.stream(env, min <> @delimiter, max)
    )
  end

  defp encode_path(path) do
    Enum.join(path, @delimiter)
  end

  defp decode_path(input) do
    String.split(input, @delimiter)
  end

  defp env(opts) do
    directory = opts_directory(opts)
    :persistent_term.get({:riptide_lmdb, directory})
  end

  defp opts_tree(opts), do: Keyword.get(opts, :tree)
  defp opts_directory(opts), do: Keyword.get(opts, :directory)
end
