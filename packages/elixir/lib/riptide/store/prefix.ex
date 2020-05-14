defmodule Riptide.Store.Prefix do
  @moduledoc false
  def range(nil, _opts), do: {[], [<<127>>]}

  def range(input, opts) do
    input = blank(input)

    case {Map.get(opts, :min), Map.get(opts, :max)} do
      {min, max} when min in ["", nil] and max in ["", nil] ->
        min = [input]
        max = [prefix(input)]
        {min, max}

      {min, max} when max in ["", nil] ->
        min = [input, min]
        max = [prefix(input)]
        {min, max}

      {min, max} when min in ["", nil] ->
        min = [input]
        max = [input, max]
        {min, max}

      {min, max} ->
        min = [input, min]
        max = [input, max]
        {min, max}
    end
  end

  def blank(""), do: <<0>>
  def blank(input), do: input

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
