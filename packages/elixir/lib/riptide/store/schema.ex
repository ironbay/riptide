defmodule Riptide.Schema do
  @moduledoc false

  defmacro schema(schema) do
    {map, _} = Code.eval_quoted(schema)
    flattened = Dynamic.flatten(map)

    funs =
      flattened
      |> Stream.flat_map(fn {path, _value} ->
        Stream.scan(path, [], fn segment, total ->
          total ++ [segment]
        end)
      end)
      |> Enum.uniq()
      |> Stream.map(fn path ->
        name_get =
          path
          |> Enum.join("_")
          |> String.to_atom()

        # name_set =
        #   [name_get, "set"]
        #   |> Enum.join("_")
        #   |> String.to_atom()

        quote do
          def unquote(name_get)(input) do
            Dynamic.get(input, unquote(path))
          end

          # def unquote(name_set)(input, value) do
          #   Dynamic.put(input, unquote(path), value)
          # end
        end
      end)
      |> Enum.to_list()

    quote do
      unquote(funs)

      def schema() do
        unquote(schema)
      end
    end
  end

  def validate_format(input, module_or_rules) when is_map(input),
    do: validate_format({input, []}, module_or_rules)

  def validate_format(input, module) when is_atom(module),
    do: validate_format(input, module.schema())

  def validate_format({input, errors}, rules) do
    input
    |> Dynamic.flatten()
    |> Stream.map(fn {path, value} ->
      {validator, opts} =
        rules
        |> Dynamic.get(path)
        |> case do
          nil -> {Riptide.Schema.Unknown, []}
          {validator, opts} -> {validator, opts}
          validator -> {validator, []}
        end

      {path, validator_alias(validator).valid?(value, opts)}
    end)
    |> Enum.filter(fn {_path, result} ->
      result != :ok
    end)
    |> case do
      result ->
        {input,
         errors ++
           Enum.map(
             result,
             fn {path, {:error, value}} ->
               {path, value}
             end
           )}
    end
  end

  def validate_required(input, rules) when is_map(input),
    do: validate_required({input, []}, rules)

  def validate_required({input, errors}, rules) when is_map(rules) do
    rules
    |> Dynamic.flatten()
    |> Enum.filter(fn {path, _} ->
      Dynamic.get(input, path) == nil
    end)
    |> case do
      result ->
        summary =
          Enum.map(result, fn {path, _} ->
            {path, :required}
          end)

        {input, errors ++ summary}
    end
  end

  def check({_input, []}), do: :ok
  def check({_input, errors}), do: {:error, errors}

  defp validator_alias(:string), do: Riptide.Schema.String
  defp validator_alias(:number), do: Riptide.Schema.Number
  defp validator_alias(result), do: result
end

defmodule Riptide.Schema.Unknown do
  @moduledoc false
  def valid?(_, _) do
    {:error, :unknown}
  end
end

defmodule Riptide.Schema.Number do
  @moduledoc false
  def valid?(input, _opts) do
    input == nil or is_number(input)
  end
end

defmodule Riptide.Schema.String do
  @moduledoc false
  def valid?(input, opts) do
    cond do
      input == nil ->
        true

      is_binary(input) ->
        cond do
          String.length(input) < Keyword.get(opts, :min_length, 0) ->
            {:error, :string_min_length}

          String.length(input) > Keyword.get(opts, :max_length, 100_000_000) ->
            {:error, :string_max_length}

          true ->
            :ok
        end

      true ->
        {:error, :string_invalid}
    end
  end
end
