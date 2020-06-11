defmodule Todolist.Test.Auth do
  use ExUnit.Case
  doctest Todolist

  test "auth flow" do
    "jack"
    |> Todolist.User.password_set("password")
    |> Riptide.mutation!()

    Todolist
  end
end
