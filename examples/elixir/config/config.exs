import Config

config :riptide,
  store: %{
    write: {Riptide.Store.LMDB, directory: "data"},
    read: {Riptide.Store.LMDB, directory: "data"},
    token: "abd"
  },
  interceptors: [
    Todolist.Todo.Permissions,
    Todolist.Todo.Schema,
    Todolist.Todo.Created,
    Todolist.Todo.Alert
  ]
