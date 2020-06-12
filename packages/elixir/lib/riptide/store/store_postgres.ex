defmodule Riptide.Store.Postgres do
  @moduledoc """
  This store persists data to a single Postgres table as materialized paths. It is best used in scenarios where your application will have multiple erlang nodes running that all need shared access to data. Note with this store Postgres is treated like a dumb key/value store and does not take advantage of any other Postgres capabilities.

  ## Configuration

  Add `postgrex` as a dependency to your `mix.exs`.

  ```elixir
  defp deps do
    [
      {:riptide, "~> 0.4.0"},
      {:postgrex,  "~> 0.15.3"}
    ]
  end
  ```

  And then you can configure the store:
  ```elixir
  config :riptide,
    store: %{
      read: {Riptide.Store.Postgres, []},
      write: {Riptide.Store.Postgres, []},
    }
  ```

  You can start up a named `Postgrex` pool manually but this module provides a convenient way for you to do that. Add this to your `application.ex`:

  ```elixir
  children = [
    {Riptide.Store.Postgres, [
      hostname: "localhost",
      database: "riptide",
      username: "postgres",
      password: "postgres",
    ]},
    Riptide,
  ]
  opts = [strategy: :one_for_one, name: Riptide.Supervisor]
  Supervisor.start_link(children, opts)
  ```

  Note, make sure the Postgres pool starts up *before* Riptide.

  ## Options
  - `:table` - name of table defaults to `riptide` (optional)
  - `:name` - name of Postgrex pool, defaults to `postgres` (optional)
  - `:transaction_timeout` - duration for transaction timeout in milliseconds, defaults to 1 minute (optional)
  """

  @behaviour Riptide.Store
  @delimiter "×"

  @doc """
  Convenience implementation of `Supervisor.child_spec/1` to start up a `Postgrex` pool with name `:postgres`

  ## Examples
  ```elixir
  children = [
    {Riptide.Store.Postgres, [
      hostname: "localhost",
      database: "riptide",
      username: "postgres",
      password: "postgres",
    ]},
    Riptide,
  ]
  opts = [strategy: :one_for_one, name: Riptide.Supervisor]
  Supervisor.start_link(children, opts)
  ```
  """
  def child_spec(opts) do
    Postgrex.child_spec(Keyword.merge([name: :postgres], opts))
  end

  @impl true
  def init(opts) do
    Postgrex.query!(
      opts_name(opts),
      """
      	CREATE TABLE IF NOT EXISTS "#{opts_table(opts)}" (
          path text COLLATE "C",
          value jsonb,
          PRIMARY KEY(path)
        );
      """,
      []
    )

    :ok
  end

  defp opts_table(opts), do: Keyword.get(opts, :table, "riptide")
  defp opts_name(opts), do: Keyword.get(opts, :name, :postgres)

  defp opts_transaction_timeout(opts),
    do: Keyword.get(opts, :transaction_timeout, :timer.minutes(1))

  @impl true
  def mutation(merges, deletes, opts) do
    opts
    |> opts_name()
    |> Postgrex.transaction(
      fn conn ->
        delete(deletes, conn, opts)
        merge(merges, conn, opts)
      end,
      timeout: :timer.hours(1)
    )
    |> case do
      {:ok, _} -> :ok
      result -> {:error, result}
    end
  end

  defp merge([], _conn, _opts), do: :ok

  defp merge(merges, conn, opts) do
    merges
    |> Stream.chunk_every(30_000)
    |> Enum.map(fn layers ->
      {_, statement, params} =
        layers
        |> Enum.reduce({1, [], []}, fn {path, value}, {index, statement, params} ->
          {
            index + 2,
            ["($#{index}, $#{index + 1})" | statement],
            [encode_path(path), value | params]
          }
        end)

      Postgrex.query!(
        conn,
        "INSERT INTO  \"#{opts_table(opts)}\"(path, value) VALUES #{Enum.join(statement, ", ")} ON CONFLICT (path) DO UPDATE SET value = excluded.value",
        params
      )
    end)
  end

  defp delete([], _conn, _opts), do: :ok

  defp delete(layers, conn, opts) do
    {arguments, statement} =
      layers
      |> Enum.with_index()
      |> Stream.map(fn {{path, _}, index} ->
        {[encode_path(path) <> "%"], "(path LIKE $#{index + 1})"}
      end)
      |> Enum.reduce({[], []}, fn {args, field}, {a, b} -> {args ++ a, [field | b]} end)

    statement = Enum.join(statement, " OR ")

    Postgrex.query!(
      conn,
      "DELETE FROM \"#{opts_table(opts)}\" WHERE #{statement}",
      arguments
    )

    :ok
  end

  defp encode_prefix(path) do
    Enum.join(path, @delimiter)
  end

  defp encode_path(path) do
    Enum.join(path, @delimiter) <> @delimiter
  end

  defp decode_path(input) do
    String.split(input, @delimiter, trim: true)
  end

  @impl true
  def query(paths, store_opts) do
    # {full, partial} = Enum.split_with(paths, fn {_path, opts} -> opts[:limit] == nil end)

    Stream.resource(
      fn ->
        {holder, conn} = txn_start(store_opts)
        Postgrex.query!(conn, "SET enable_seqscan = OFF;", [])
        {holder, conn}
      end,
      fn
        {holder, conn} ->
          {Stream.concat([
             query_partial(paths, conn)
             #  query_full(full, conn)
           ]), holder}

        holder ->
          {:halt, holder}
      end,
      fn holder -> txn_end(holder) end
    )
  end

  defp query_partial(paths, conn) do
    paths
    |> Stream.map(fn {path, opts} ->
      {path, query_path(path, opts, conn)}
    end)
  end

  defp query_full([], _conn), do: []

  defp query_full(paths, conn) do
    {values, args, _} =
      Enum.reduce(paths, {[], [], 0}, fn {path, opts}, {values, args, count} ->
        combined = encode_prefix(path)
        {min, max} = Riptide.Store.Prefix.range(combined, opts)

        {
          values ++ ["($#{count + 1}, $#{count + 2}, $#{count + 3})"],
          args ++ [combined, encode_path(min), encode_path(max)],
          count + 3
        }
      end)

    statement = """
    WITH ranges (prefix, min, max) AS (VALUES #{Enum.join(values, ", ")})
    SELECT ranges.prefix, path, value FROM riptide JOIN ranges ON riptide.path >= ranges.min AND riptide.path < ranges.max
    """

    conn
    |> Postgrex.stream(
      statement,
      args,
      max_rows: 1000
    )
    |> Stream.flat_map(fn item -> item.rows end)
    |> Stream.chunk_by(fn [prefix, _path, _value] -> prefix end)
    |> Stream.map(fn chunk ->
      [prefix, _, _] = Enum.at(chunk, 0)

      {
        decode_path(prefix),
        Stream.map(chunk, fn [_, path, value] -> {decode_path(path), value} end)
      }
    end)
  end

  defp query_path(path, opts, conn) do
    combined = encode_prefix(path)
    {min, max} = Riptide.Store.Prefix.range(combined, opts)

    conn
    |> Postgrex.stream(
      "SELECT path, value FROM riptide WHERE path >= $1 AND path < $2 ORDER BY path ASC",
      [encode_path(min), encode_path(max)]
    )
    |> Stream.flat_map(fn item -> item.rows end)
    |> Stream.map(fn [path, value] -> {decode_path(path), value} end)
  end

  defp txn_start(store_opts) do
    self = self()

    {:ok, child} =
      Task.start_link(fn ->
        Postgrex.transaction(
          opts_name(store_opts),
          fn conn ->
            send(self, {:conn, conn})

            receive do
              {:conn, :done} -> :ok
            end
          end,
          timeout: opts_transaction_timeout(store_opts)
        )
      end)

    conn =
      receive do
        {:conn, conn} -> conn
      end

    {child, conn}
  end

  defp txn_end(holder) do
    send(holder, {:conn, :done})
  end
end
