defmodule Riptide.Test.Subscribe do
  use ExUnit.Case

  test "implementation" do
    Riptide.Subscribe.watch([])
    {creature, creature_info} = Riptide.Test.Data.hammerhead()

    mut = Riptide.Mutation.merge(["creatures", creature], creature_info)
    Riptide.Subscribe.broadcast_mutation(mut)

    {:mutation, ^mut} =
      receive do
        result -> result
      end
  end
end
