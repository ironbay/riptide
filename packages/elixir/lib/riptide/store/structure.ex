defmodule Riptide.Store.Structure do
  defstruct [:table, :columns]

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :structures, accumulate: true)
      import Riptide.Store.Structure

      @before_compile Riptide.Store.Structure
    end
  end

  defmacro __before_compile__(env) do
    structures = Module.get_attribute(env.module, :structures)

    quote do
      def all() do
        unquote(structures)
      end
    end
  end

  defmacro structure(table, prefix, columns) do
    structure =
      Macro.escape(%Riptide.Store.Structure{
        columns: columns,
        table: table
      })

    prefix =
      case prefix do
        [] ->
          quote do: _

        _ ->
          quote do: [unquote_splicing(prefix) | rest]
      end

    quote do
      @structures Macro.escape(unquote(structure))
      def for_path(unquote(prefix)) do
        unquote(structure)
      end
    end
  end
end
