defmodule OceanTest do
  use ExUnit.Case
  doctest Ocean

  test "greets the world" do
    assert Ocean.hello() == :world
  end
end
