defmodule TodoList.Test.Auth do
  use ExUnit.Case
  doctest TodoList

  test "auth flow" do
    "jack"
    |> TodoList.User.password_set("password")
    |> Riptide.mutation!()

    TodoList
  end
end
