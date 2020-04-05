import Config

config :riptide,
  store: %{
    write: {Riptide.Store.LMDB, directory: "data"},
    read: {Riptide.Store.LMDB, directory: "data"}
  },
  interceptors: [
    TodoList.Permissions,
    TodoList.Todo.Created,
    TodoList.Todo.Alert
  ]
