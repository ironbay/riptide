defmodule Riptide.Schema do
  defmacro schema(body) do
    {schema, _} = Code.eval_quoted(body)
    flattened = Dynamic.flatten(schema)

    validate_steps =
      Enum.map(flattened, fn {path, value} ->
        {mod, opts} = mod_opts(value)

        quote do
          path = unquote(path)

          case Dynamic.get(input, path) do
            nil ->
              []

            result ->
              validate_child(path, result, unquote(mod), unquote(opts))
          end
        end
      end)

    getters =
      schema
      |> Dynamic.flatten()
      |> Stream.flat_map(fn {path, _} ->
        Stream.scan(path, [], fn segment, total ->
          total ++ [segment]
        end)
      end)
      |> Enum.uniq()
      |> Stream.map(fn path ->
        name_get =
          ["get" | path]
          |> Enum.join("_")
          |> String.to_atom()

        quote do
          def unquote(name_get)(input) do
            Dynamic.get(input, unquote(path))
          end
        end
      end)
      |> Enum.to_list()

    quote do
      unquote(getters)

      def validate(input, _opts \\ []) do
        unquote(validate_steps)
        |> List.flatten()
        |> case do
          [] ->
            :ok

          result ->
            {:error, result}
        end
      end
    end
  end

  def validate_child(path, value, mod, opts) do
    case mod.validate(value, opts) do
      :ok ->
        []

      {:error, result} when is_list(result) ->
        Enum.map(result, fn {sub_path, val} -> {path ++ sub_path, val} end)

      {:error, result} ->
        [{path, result}]
    end
  end

  def mod_opts({mod, opts}), do: {from_alias(mod), opts}
  def mod_opts(mod), do: mod_opts({mod, []})

  alias Riptide.Schema.Type

  def from_alias(:number), do: Type.Number
  def from_alias(:string), do: Type.String
  def from_alias(:map), do: Type.Map
  def from_alias(:any), do: Type.Any
  def from_alias(:enum), do: Type.Enum
  def from_alias(:boolean), do: Type.Boolean
  def from_alias(mod), do: mod
end
