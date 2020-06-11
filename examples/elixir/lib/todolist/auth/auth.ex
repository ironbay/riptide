defmodule Todolist.Auth do
  def session_create(key, data) do
    Riptide.Mutation.merge(["auth:sessions", key], data)
  end

  def session_info(key), do: Riptide.query_path!(["auth:sessions", key])
end
