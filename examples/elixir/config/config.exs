import Config

config :riptide,
  store: %{
    write: {Riptide.Store.LMDB, directory: "data"},
    read: {Riptide.Store.LMDB, directory: "data"}
  },
  interceptors: [
    Ocean.Permissions,
    Ocean.Todo.Created,
    Ocean.Todo.Alert
  ]
