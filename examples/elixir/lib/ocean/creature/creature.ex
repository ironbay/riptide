defmodule Ocean.Todo do
  def info(key), do: Riptide.query_path!(["todos", key])
  def stream(), do: Riptide.stream(["todos"])
end
