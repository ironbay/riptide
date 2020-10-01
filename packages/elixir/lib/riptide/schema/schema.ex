defmodule Riptide.Schema do
  defmacro schema(body) do
    {schema, _} = Code.eval_quoted(body)

    steps =
      schema
      |> Dynamic.flatten()
      |> Enum.map(fn {path, value} ->
        {mod, opts} =
          case value do
            {mod, opts} -> {mod, opts}
            mod -> {mod, []}
          end

        mod = from_alias(mod)

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

    quote do
      def validate(input), do: validate(input, [])

      @doc false
      def validate(input, _opts) do
        unquote(steps)
        |> Enum.flat_map(& &1)
        |> IO.inspect()
        |> Enum.to_list()
        |> case do
          [] -> :ok
          result -> {:error, result}
        end
      end
    end
  end

  def validate_child(path, value, mod, opts) do
    case mod.validate(value, opts) do
      {:error, result} when is_list(result) ->
        Enum.map(result, fn {sub_path, error} ->
          {:error, {path ++ sub_path, error}}
        end)

      {:error, result} ->
        [{:error, {path, result}}]

      :ok ->
        []
    end
  end

  alias Riptide.Schema.Type

  def from_alias(:string), do: Type.String
  def from_alias(:number), do: Type.Number
  def from_alias(:map), do: Type.Map
  def from_alias(mod), do: mod
end
