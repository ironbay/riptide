defmodule Riptide.Test.Subscribe do
  use ExUnit.Case

  test "implementation" do
    Riptide.Subscribe.watch([])
    {creature, creature_info} = Riptide.Test.Data.clean_tank()

    mut = Riptide.Mutation.put_merge(["creatures", creature], creature_info)
    Riptide.Subscribe.broadcast_mutation(mut)

    {:mutation, ^mut} =
      receive do
        result -> result
      end
  end

  test "delete watched path" do
    Riptide.Subscribe.watch(["root", "child"])

    delete = Riptide.Mutation.put_delete(["root", "child"])

    mut = %Riptide.Mutation{
      delete: %{
        "root" => %{
          "child" => 1
        }
      },
      merge: %{
        "root" => %{
          "child" => %{
            "a" => 1,
            "b" => 1
          }
        }
      }
    }

    Riptide.Subscribe.broadcast_mutation(mut)

    {:mutation, ^mut} =
      receive do
        result -> result
      end
  end
end
