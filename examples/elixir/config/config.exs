import Config

config :riptide,
  store: %{
    write: {Riptide.Store.Postgres, []},
    read: {Riptide.Store.Postgres, []}
  },
  interceptors: [
    TodoList.Permissions,
    TodoList.Todo.Created,
    TodoList.Todo.Alert
  ]
