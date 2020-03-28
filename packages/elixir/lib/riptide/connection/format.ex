defmodule Riptide.Format.JSON do
  def decode(data), do: Jason.decode(data)
  def encode(data), do: Jason.encode(data)
end
