defmodule Todolist.Todo do
  import Riptide.Schema

  schema(%{
    "id" => :string,
    "text" => :string,
    "user" => :string,
    "times" => %{
      "created" => :number
    }
  })

  def create(id, user, text) do
    Riptide.Mutation.put_merge(["user:todos", user, id], %{
      "id" => id,
      "user" => user,
      "text" => text
    })
  end

  def uuid(), do: "TOD" <> Riptide.UUID.descending()
end
