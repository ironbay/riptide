defmodule Riptide.Query do
  def flatten(query) do
    case shallow?(query) do
      true -> [{[], query}]
      false -> flatten(query, [])
    end
  end

  def flatten(query, path) do
    query
    |> Stream.flat_map(fn {key, value} ->
      full = path ++ [key]

      case shallow?(value) do
        true ->
          [
            {full,
             [
               min: value[:min] || value["min"],
               max: value[:max] || value["max"],
               limit: value[:limit] || value["limit"],
               subscribe: value[:subscribe] || value["subscribe"]
             ]
             |> Stream.filter(fn {_key, value} -> value != nil end)
             |> Enum.into(%{})}
          ]

        false ->
          flatten(value, full)
      end
    end)
  end

  defp shallow?(input) do
    input
    |> Map.values()
    |> Enum.all?(&(!is_map(&1)))
  end
end
