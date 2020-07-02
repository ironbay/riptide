defmodule Riptide.Store.Memory do
  @moduledoc """
  This store persists all data into an ETS table. It will not survive restarts and is best used for local development or in conjunction with `Riptide.Store.Composite` to keep a portion of the tree in memory.

  ## Configuration

  ```elixir
  config :riptide,
    store: %{
      read: {Riptide.Store.Memory, []},
      write: {Riptide.Store.Memory, []},
    }
  ```

  ## Options

  - `:table` - name for ETS table, defaults to `:riptide_table` (optional)
  """

  @behaviour Riptide.Store

  @impl true
  def init(opts) do
    opts
    |> opts_table()
    |> :ets.new([
      :ordered_set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    :ok = snapshot_load(opts)

    :ok
  end

  defp opts_table(opts), do: Keyword.get(opts, :table, :riptide_table)
  defp opts_snapshot(opts), do: Keyword.get(opts, :snapshot, nil)

  def snapshot_write(opts) do
    case opts_snapshot(opts) do
      nil ->
        :ok

      result ->
        data = Riptide.Store.query(%{}, __MODULE__, opts)
        json = Jason.encode!(data)
        File.write!(result, json)
        :ok
    end
  end

  def snapshot_load(opts) do
    with path when path != nil <- opts_snapshot(opts),
         {:ok, data} <- File.read(path),
         {:ok, json} <- Jason.decode(data),
         :ok = mutation(Dynamic.flatten(json), [], opts) do
      :ok
    else
      _ -> :ok
    end
  end

  @impl true
  def mutation(merges, deletes, opts) do
    table = opts_table(opts)

    deletes
    |> Enum.each(fn {path, _} ->
      {last, rest} = List.pop_at(path, -1)
      {min, max} = Riptide.Store.Prefix.range(last, %{})
      min = rest ++ min
      max = rest ++ max

      table
      |> iterate_keys(min, max)
      |> Enum.each(fn path -> :ets.delete(table, path) end)
    end)

    :ets.insert(
      table,
      merges
      |> Stream.map(fn {path, value} -> {path, Jason.encode!(value)} end)
      |> Enum.to_list()
    )

    :ok = snapshot_write(opts)
    :ok
  end

  @impl true
  def query(paths, opts) do
    table = opts_table(opts)
    Stream.map(paths, fn {path, opts} -> {path, query_path(table, path, opts)} end)
  end

  defp query_path(table, path, opts) do
    {last, rest} = List.pop_at(path, -1)
    {min, max} = Riptide.Store.Prefix.range(last, opts)
    min = rest ++ min
    max = rest ++ max

    table
    |> iterate_keys(min, max)
    |> Stream.map(&:ets.lookup(table, &1))
    |> Stream.map(&List.first/1)
    |> Stream.filter(fn item -> item !== nil end)
    |> Stream.map(fn {path, value} -> {path, Jason.decode!(value)} end)
  end

  defp iterate_keys(table, min, max) do
    Stream.resource(
      fn -> :start end,
      fn
        :start ->
          {[min], min}

        key ->
          case :ets.next(table, key) do
            :"$end_of_table" -> {:halt, nil}
            result when result >= max -> {:halt, nil}
            result -> {[result], result}
          end
      end,
      fn _ -> :skip end
    )
  end
end
