defmodule TodoList.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: TodoList.Worker.start_link(arg)
      # {TodoList.Worker, arg}
      {Riptide.Store.Postgres,
       username: "postgres", hostname: "localhost", password: "password", database: "postgres"},
      {Riptide, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TodoList.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
