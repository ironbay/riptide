defmodule Riptide.Branch do
  defstruct [:name, :columns, :schema]

  defmacro __using__(path) do
    quoted =
      path
      |> Stream.scan([], fn item, collect ->
        collect ++ [item]
      end)
      |> Stream.map(fn path ->
        vars = Enum.filter(path, fn item -> !is_binary(item) end)

        quote do
          def query(unquote_splicing(vars)) do
            Riptide.query_path!(unquote(path))
          end

          def delete(unquote_splicing(vars)) do
            Riptide.Mutation.put_delete(unquote(path))
          end
        end
      end)
      |> Enum.to_list()

    definition =
      Enum.map(path, fn
        {atom, _, _} -> atom
        bin -> bin
      end)

    vars = Enum.filter(path, fn item -> !is_binary(item) end)

    quote do
      import Riptide.Schema
      unquote(quoted)

      def merge(unquote_splicing(vars), data) do
        Riptide.Mutation.put_merge(unquote(path), data)
      end

      def branch() do
        unquote(definition)
      end
    end
  end
end
