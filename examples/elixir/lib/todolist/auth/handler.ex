defmodule Todolist.Auth.Handler do
  use Riptide.Handler

  def handle_call("todo.login", %{"email" => email, "password" => password}, state) do
    with {:ok, user} <-
           email
           |> String.downcase()
           |> Todolist.User.from_email(),
         true <- Todolist.User.password_valid?(user, password) do
      session = Riptide.UUID.ascending()

      session
      |> Todolist.Auth.session_create(%{"user" => user})
      |> Riptide.mutation!()

      {:reply, session, state}
    else
      _ -> {:error, :auth_credentials_invalid, state}
    end
  end

  def handle_call("todo.upgrade", session, state) do
    case Todolist.Auth.session_info(session) do
      %{"user" => user} -> {:reply, user, %{user: user}}
      _ -> {:error, :auth_session_invalid, state}
    end
  end
end
