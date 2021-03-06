defmodule Riptide.Test.Mutation do
  use ExUnit.Case
  alias Riptide.Mutation
  doctest Riptide.Mutation

  @mutations "../test/mutations.json"
             |> File.read!()
             |> Jason.decode!()
             |> Enum.map(fn [title, action, left, right, expected] ->
               left = Mutation.new(left["merge"], left["delete"])
               right = Mutation.new(right["merge"], right["delete"])
               expected = Mutation.new(expected["merge"], expected["delete"])

               [title, action, left, right, expected]
             end)

  for [title, action, left, right, expected] <- @mutations do
    left = Macro.escape(left)
    right = Macro.escape(right)
    expected = Macro.escape(expected)

    test title do
      case unquote(action) do
        "combine" ->
          assert Mutation.combine(unquote(left), unquote(right)) === unquote(expected)
      end
    end
  end
end
