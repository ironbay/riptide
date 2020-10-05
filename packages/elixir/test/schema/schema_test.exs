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
      "tags" => {:list, type: :string},
      "key" => :string,
      "depends_on" => {:map, type: Riptide.Test.Schema.Todo}
    }
  end

  test "getter" do
    assert nil == Todo.get_times_created(%{})
  end

  test "empty" do
    assert :ok = Todo.validate(%{})
  end

  test "nested" do
    assert {:error,
            [
              {["depends_on", "test", "key"], :not_string}
            ]} =
             Todo.validate(%{
               "depends_on" => %{
                 "test" => %{
                   "key" => 1234
                 }
               }
             })
  end

  test "list" do
    assert {:error,
            [
              {["tags", 1], :not_string}
            ]} = Todo.validate(%{"tags" => ["tag1", 0]})
  end

  test "schema" do
    assert %{} = Todo.schema()
  end
end
