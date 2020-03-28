defmodule Ocean.Creature do
  def info(key), do: Riptide.query_path!(["creatures", key])
  def stream(), do: Riptide.stream(["creatures"])
end
