defmodule Riptide.Test.Schema do
  use ExUnit.Case

  defmodule Todo do
    import Riptide.Schema
    alias Riptide.Schema.Types

    schema %{
      "times" => %{
        "created" => :number,
        "updated" => :number
      },
      "key" => :string,
      "depends_on" => {:map, type: Riptide.Test.Schema.Todo}
    }
  end

  test "schema" do
    assert :ok = Todo.validate(%{})

    assert :ok =
             Todo.validate(%{
               "times" => %{
                 "created" => 1234
               },
               "depends_on" => %{
                 "test" => %{
                   "key" => 1234
                 }
               }
             })
  end
end
