defmodule Riptide.Test.Mutation do
  use ExUnit.Case
  alias Riptide.Mutation

  test "combine mutations" do
    mutations =
      "../test/mutations.json"
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(fn [title, action, left, right, expected] ->
        left = Mutation.new(left["merge"], left["delete"])
        right = Mutation.new(right["merge"], right["delete"])
        expected = Mutation.new(expected["merge"], expected["delete"])

        [title, action, left, right, expected]
      end)

    for [title, action, left, right, expected] <- mutations do
      if action === "combine" do
        assert expected == Mutation.combine(left, right), "#{action}: #{title}"
      end
    end
  end
end
