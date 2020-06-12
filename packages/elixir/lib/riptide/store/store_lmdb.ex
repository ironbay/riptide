defmodule Riptide.Store.LMDB do
  @moduledoc """

  """
  @behaviour Riptide.Store
  @delimiter "×"

  def init(directory: directory) do
    {:ok, env} = Bridge.LMDB.open_env(directory)

    :persistent_term.put({:riptide, directory}, env)
    :ok
  end

  def env(directory: directory) do
    :persistent_term.get({:riptide, directory})
  end

  def mutation(merges, deletes, opts) do
    env = env(opts)

    Bridge.LMDB.batch_write(
      env,
      Enum.map(merges, fn {path, value} ->
        {encode_path(path), Jason.encode!(value)}
      end),
      Enum.flat_map(deletes, fn {path, _} ->
        env
        |> iterate(path, %{})
        |> Enum.map(fn {path, _val} -> path end)
      end)
    )
  end

  def query(layers, opts) do
    env = env(opts)

    layers
    |> Stream.map(fn {path, opts} ->
      {
        path,
        env
        |> iterate(path, opts)
        |> Stream.map(fn {path, value} -> {decode_path(path), Jason.decode!(value)} end)
      }
    end)
  end

  def iterate(env, path, opts) do
    combined = Enum.join(path, @delimiter)
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

  def encode_path(path) do
    Enum.join(path, @delimiter)
  end

  def decode_path(input) do
    String.split(input, @delimiter)
  end
end
