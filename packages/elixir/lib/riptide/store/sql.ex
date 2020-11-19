defmodule Riptide.Store.SQL do
  defstruct [:table, :columns, :where, :mode, :set]

  def new(table) do
    %Riptide.Store.SQL{
      table: table,
      columns: [],
      set: [],
      where: %{}
    }
  end

  def select(table) do
    table
    |> new()
    |> Map.put(:mode, "SELECT")
  end

  def update(table) do
    table
    |> new()
    |> Map.put(:mode, "UPDATE")
  end

  def delete(table) do
    table
    |> new()
    |> Map.put(:mode, "DELETE")
  end

  def columns(query, columns) do
    %{query | columns: query.columns ++ columns}
  end

  def set(query, set) do
    %{query | set: query.set ++ set}
  end

  def where(query, where) do
    %{
      query
      | where:
          Map.merge(
            query.where,
            where
            |> Enum.filter(fn {k, _v} -> k != :_ end)
            |> Enum.into(%{})
          )
    }
  end

  def to_sql(query) do
    list = Enum.into(query.where, [])

    {
      [
        "#{query.mode} #{Enum.join(query.columns, ", ")}",
        if query.mode !== "UPDATE" do
          "FROM"
        end,
        query.table,
        if query.set != [] do
          [
            "SET ",
            query.set
            |> Keyword.keys()
            |> Stream.with_index()
            |> Stream.map(fn {key, index} ->
              "#{key} = $#{index + 1}"
            end)
            |> Enum.join(",")
          ]
        end,
        if list != [] do
          [
            "WHERE ",
            list
            |> Keyword.keys()
            |> Stream.map(&Atom.to_string/1)
            |> Stream.with_index()
            |> Stream.map(fn {column, index} ->
              column <> " = $#{index + 1 + Enum.count(query.set)}"
            end)
            |> Enum.join(" AND\n")
          ]
        end
      ]
      |> List.flatten()
      |> Stream.filter(& &1)
      |> Enum.join("\n"),
      Keyword.values(query.set) ++ Keyword.values(list)
    }
  end
end

defmodule Riptide.Store.Next.SQL do
  defstruct [
    :table,
    :mode,
    :select,
    :where,
    :set
  ]

  def new(table) do
    %__MODULE__{
      table: table,
      mode: :unknown,
      select: [],
      where: [],
      set: []
    }
  end

  def select(%__MODULE__{} = token, columns) do
    %{
      token
      | select: token.select ++ columns
    }
  end

  def select(table, columns) when is_binary(table) do
    %{
      new(table)
      | mode: :select
    }
    |> select(columns)
  end

  def where(%__MODULE__{} = token, clauses) do
    where(token, :eq, clauses)
  end

  def where(%__MODULE__{} = token, comparator, clauses) do
    built =
      clauses
      |> Stream.filter(fn {_col, val} -> val != nil end)
      |> Stream.map(fn {col, val} -> {col, comparator, val} end)
      |> Enum.to_list()

    %{
      token
      | where: token.where ++ built
    }
  end

  def to_sql(%__MODULE__{mode: :select} = token) do
    sql =
      [
        "SELECT",
        Enum.join(token.select, ", "),
        "FROM",
        token.table,
        if token.where != [] do
          [
            "WHERE",
            token.where
            |> Stream.with_index()
            |> Stream.map(fn {{col, comp, _val}, index} ->
              [
                col,
                case comp do
                  :eq -> "="
                  :lt -> "<"
                  :lte -> "<="
                  :gt -> ">"
                  :gte -> ">="
                end,
                "$#{index + 1}"
              ]
            end)
            |> Stream.intersperse("AND")
            |> Enum.to_list()
          ]
        end
      ]
      |> List.flatten()
      |> Stream.filter(& &1)
      |> Enum.join(" ")

    {sql, Enum.map(token.where, fn {_col, _comp, val} -> val end)}
  end
end
