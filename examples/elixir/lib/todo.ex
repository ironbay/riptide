defmodule TodoList do
  @moduledoc """
  Documentation for `TodoList`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TodoList.hello()
      :world

  """
  def find_key_match(labels, keys) do
    num_key_terms = Kernel.length(keys)

    Stream.resource(
      fn -> labels end,
      fn
        [] -> {:halt, []}
        [head | rest] -> {[{head, rest}], rest}
      end,
      fn _ -> :ok end
    )
    |> Stream.filter(fn {label, _rest} ->
      string_compare(label.description, Enum.at(keys, 0)) > @compare_threshold
    end)
    |> Stream.filter(fn {_label, rest} ->
      s1 =
        rest
        |> Enum.map(fn item -> item.description end)
        |> Enum.join(" ")

      s2 = Enum.join(keys, " ")

      string_compare(s1, s2) > @compare_threshold
    end)

    labels
    |> Enum.with_index()
    |> Enum.map(fn {val, i} -> Map.put(val, :index, i) end)
    |> Enum.filter(fn label ->
      string_compare(label.description, Enum.at(keys, 0)) > @compare_threshold
    end)
    |> Enum.filter(fn x ->
      s1 =
        Enum.slice(labels, Map.get(x, :index), num_key_terms)
        |> Enum.map(fn x -> x.description end)
        |> Enum.join(" ")

      s2 = Enum.join(keys, " ")
      string_compare(s1, s2) > @compare_threshold
    end)
  end
end
