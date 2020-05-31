import Config

config :riptide,
  store: %{
    write: {Riptide.Store.LMDB, directory: "data"},
    read: {Riptide.Store.LMDB, directory: "data"},
    token: "abd"
  },
  interceptors: [
    TodoList.Permissions,
    TodoList.Todo.Created,
    TodoList.Todo.Alert
  ]
