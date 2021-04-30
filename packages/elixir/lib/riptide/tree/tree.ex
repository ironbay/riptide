defmodule Riptide.Tree do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :branches, accumulate: true)
      import Riptide.Tree

      @before_compile Riptide.Tree
    end
  end

  defmacro __before_compile__(env) do
    branches = Module.get_attribute(env.module, :branches)

    quote do
      def for_path(path) do
        raise "Schema not defined for path #{inspect(path)}"
      end

      def all() do
        unquote(branches)
      end
    end
  end

  defmacro branch(path_or_module, opts \\ []) do
    cond do
      is_list(path_or_module) ->
        do_branch(path_or_module, opts)

      true ->
        {module, []} = Code.eval_quoted(path_or_module)

        module.branch()
        |> Enum.map(fn
          item when is_atom(item) -> {item, [], nil}
          item -> item
        end)
        |> do_branch(opts)
    end
  end

  defp do_branch(path, opts \\ []) do
    {prefix, _rest} = Enum.split_while(path, &is_binary/1)

    name =
      Keyword.get(
        opts,
        :name,
        prefix
        |> Enum.map(&Regex.replace(~r/\W/, &1, "_"))
        |> Enum.join("_")
      )

    columns =
      Enum.map(path, fn
        binary when is_binary(binary) -> :_
        {atom, _, _} when is_atom(atom) -> atom
        atom when is_atom(atom) -> atom
        _ -> raise "Branch paths must be atoms or strings"
      end)

    branch =
      Macro.escape(%Riptide.Branch{
        name: name,
        columns: columns,
        schema:
          case Code.eval_quoted(Keyword.get(opts, :schema, [])) do
            {mod, _} when is_atom(mod) -> mod
            _ -> nil
          end
      })

    match =
      case prefix do
        [] -> quote do: _
        _ -> quote do: [unquote_splicing(prefix) | rest]
      end

    quote do
      @branches Macro.escape(unquote(branch))
      def for_path(unquote(match)) do
        unquote(branch)
      end
    end
  end
end
