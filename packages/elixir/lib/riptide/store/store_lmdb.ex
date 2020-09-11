defmodule Riptide.Store.LMDB do
  @moduledoc """
  This store persists data to [LMDB](https://symas.com/lmdb/) using a bridge built in Rust. LMDB is a is a fast, memory mapped key value store that is persisted to a single file. It's a great choice for many projects that need persistence but want to avoid the overhead of setting up a standalone database.

  ## Configuration

  This store has a dependency on the Rust toolchain which can be installed via [rustup](https://rustup.rs/). Once installed, add the `bridge_lmdb` dependency to your `mix.exs`.

  ```elixir
  defp deps do
    [
      {:riptide, "~> 0.4.0"},
      {:bridge_lmdb, "~> 0.1.1"}
    ]
  end
  ```

  And then you can configure the store:
  ```elixir
  config :riptide,
    store: %{
      read: {Riptide.Store.LMDB, directory: "data"},
      write: {Riptide.Store.LMDB, directory: "data"},
    }
  ```

  ## Options

    - `:directory` - directory where the database is stored (required)
  """
  @behaviour Riptide.Store
  @delimiter "×"

  @impl true
  def init(directory: directory) do
    {:ok, env} = Bridge.LMDB.open_env(directory)

    :persistent_term.put({:riptide, directory}, env)
    :ok
  end

  defp env(directory: directory) do
    :persistent_term.get({:riptide, directory})
  end

  @impl true
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

  @impl true
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

  defp encode_path(path) do
    Enum.join(path, @delimiter)
  end

  defp decode_path(input) do
    String.split(input, @delimiter)
  end
end
