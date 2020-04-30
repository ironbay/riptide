defmodule Riptide.Store.Prefix do
  @moduledoc false
  def range(nil, _opts), do: {[], [<<127>>]}

  def range(input, opts) do
    input =
      case input do
        "" -> <<0>>
        _ -> input
      end

    case {Map.get(opts, :min), Map.get(opts, :max)} do
      {nil, nil} ->
        min = [input]
        max = [prefix(input)]
        {min, max}

      {min, nil} ->
        min = [input, min]
        max = [prefix(input)]
        {min, max}

      {nil, max} ->
        min = [input]
        max = [input, max]
        {min, max}

      {min, max} ->
        min = [input, min]
        max = [input, max]
        {min, max}
    end
  end

  def prefix(<<0>>) do
    <<127>>
  end

  def prefix(<<head>>) do
    <<head + 1>>
  end

  def prefix(<<head>> <> tail) do
    <<head>> <> prefix(tail)
  end
end
