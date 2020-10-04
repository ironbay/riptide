defmodule Riptide.Test.Tree do
  use ExUnit.Case

  defmodule Example do
    use Riptide.Tree

    branch ["todo:info", todo_key]
    branch ["business:info", business_key], name: "businesses"
  end

  @todo_info %Riptide.Tree.Branch{
    columns: [:_, :todo_key],
    name: "todo_info"
  }

  @business_info %Riptide.Tree.Branch{
    columns: [:_, :business_key],
    name: "businesses"
  }

  test "match" do
    assert @todo_info == Example.for_path(["todo:info"])
  end

  test "name" do
    assert @business_info == Example.for_path(["business:info"])
  end

  test "all" do
    assert [
             @business_info,
             @todo_info
           ] == Example.all()
  end
end
