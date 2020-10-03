defmodule Riptide.Store.TreePostgres do
  @behaviour Riptide.Store
  import Riptide.Store.SQL

  @impl true
  def init(opts) do
    tree = opts_tree(opts)

    if tree == nil do
      raise ":tree is not defined"
    end

    tree.all()
    |> Stream.map(fn branch ->
      keys =
        branch.columns
        |> Stream.filter(fn item -> item !== :_ end)
        |> Stream.map(&Atom.to_string/1)

      Postgrex.query!(
        opts_name(opts),
        """
        CREATE TABLE IF NOT EXISTS "#{branch.name}" (
        data jsonb,
        #{keys |> Stream.map(fn key -> key <> " text COLLATE \"C\"" end) |> Enum.join(", ")},
        PRIMARY KEY (#{Enum.join(keys, ", ")})
        )
        """,
        []
      )
    end)
    |> Stream.run()

    :ok
  end

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

    :ok
  end

  def delete([], _conn, _opts), do: :ok

  def delete(deletes, conn, store_opts) do
    tree = opts_tree(store_opts)

    deletes
    |> Stream.map(fn {path, _opts} ->
      branch = tree.for_path(path)
      {columns, _extra_columns, extra_path} = zip(branch.columns, path)

      cond do
        extra_path == [] ->
          {sql, params} =
            branch.name
            |> delete()
            |> where(columns)
            |> to_sql()

          Postgrex.query!(
            conn,
            sql,
            params
          )

        extra_path != [] ->
          {sql, params} =
            branch.name
            |> select()
            |> columns(["data"])
            |> where(columns)
            |> to_sql()

          existing =
            conn
            |> Postgrex.query!(sql, params)
            |> Map.get(:rows)
            |> Enum.at(0, [])
            |> Enum.at(0)

          {sql, params} =
            (existing || %{})
            |> Dynamic.delete(extra_path)
            |> case do
              next when next == %{} ->
                branch.name
                |> delete()
                |> where(columns)
                |> to_sql()

              next ->
                branch.name
                |> update()
                |> set(data: next)
                |> where(columns)
                |> to_sql()
            end

          Postgrex.query!(conn, sql, params)
      end
    end)
    |> Stream.run()
  end

  def merge([], _conn, _opts), do: :ok

  def merge(merges, conn, store_opts) do
    tree = opts_tree(store_opts)

    merges
    |> Stream.map(fn {path, val} ->
      branch = tree.for_path(path)
      {columns, [], extra_path} = zip(branch.columns, path)
      {branch.name, columns, extra_path, val}
    end)
    |> Enum.group_by(
      fn {name, columns, _path, _val} ->
        {name, columns}
      end,
      fn {__name, _keys, path, val} ->
        {path, val}
      end
    )
    |> Stream.map(fn {{name, columns}, values} ->
      {sql, params} =
        name
        |> select()
        |> columns(["data"])
        |> where(columns)
        |> to_sql()

      existing =
        conn
        |> Postgrex.query!(sql, params)
        |> Map.get(:rows)
        |> Enum.at(0, [])
        |> Enum.at(0)

      data =
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

      {inserts, values, params} =
        columns
        |> Stream.with_index()
        |> Enum.reduce({["data"], ["$1"], [data]}, fn {{column, column_val}, index},
                                                      {columns, values, params} ->
          {
            ["#{column}" | columns],
            ["$#{index + 2}" | values],
            params ++ [column_val]
          }
        end)

      Postgrex.query!(
        conn,
        """
        INSERT INTO #{name}
        (#{Enum.join(inserts, ", ")})
        VALUES
        (#{Enum.join(values, ", ")})
        ON CONFLICT (#{columns |> Keyword.keys() |> Enum.join(",")})
        DO UPDATE SET data = $1
        """,
        params
      )
    end)
    |> Stream.run()
  end

  @impl true
  def query(layers, store_opts) do
    tree = opts_tree(store_opts)

    layers
    |> Stream.map(fn {path, _opts} ->
      branch = tree.for_path(path)
      {columns, extra_columns, extra_path} = zip(branch.columns, path)

      cond do
        extra_columns == [] ->
          {sql, params} =
            branch.name
            |> select()
            |> columns(["data"])
            |> where(columns)
            |> to_sql()

          Postgrex.query!(
            opts_name(store_opts),
            sql,
            params
          )
          |> Map.get(:rows, [])
          |> Enum.at(0, [])
          |> Enum.at(0)
          |> case do
            result -> {path, [{path, Dynamic.get(result, extra_path)}]}
          end

        extra_columns != [] ->
          {sql, params} =
            branch.name
            |> select()
            |> columns(extra_columns)
            |> columns(["data"])
            |> where(columns)
            |> to_sql()

          {path,
           Postgrex.query!(
             opts_name(store_opts),
             sql,
             params
           )
           |> Map.get(:rows, [])
           |> Enum.map(fn row ->
             {prefix, [data]} = Enum.split(row, Enum.count(extra_columns))
             {path ++ prefix, data}
           end)}
      end
    end)
  end

  defp opts_name(opts), do: Keyword.get(opts, :name, :postgres)
  defp opts_tree(opts), do: Keyword.get(opts, :tree)

  defp opts_transaction_timeout(opts),
    do: Keyword.get(opts, :transaction_timeout, :timer.minutes(1))

  def zip(left, right) do
    do_zip(left, right)
  end

  def do_zip([], []) do
    {[], [], []}
  end

  def do_zip(left, []) do
    {[], left, []}
  end

  def do_zip([], right) do
    {[], [], right}
  end

  def do_zip([:_ | lt], [_ | rt]) do
    do_zip(lt, rt)
  end

  def do_zip([lh | lt], [rh | rt]) do
    {zipped, left, right} = zip(lt, rt)

    {[
       {lh, rh} | zipped
     ], left, right}
  end
end
