defmodule Riptide.Format.JSON do
  @moduledoc false
  def decode(data), do: Jason.decode(data)
  def encode(data), do: Jason.encode(data)
end
