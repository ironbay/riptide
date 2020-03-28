defmodule Riptide.Config do
  use Brine

  config :riptide, %{
    commands: [],
    scheduler: true,
    store: %{
      write: {Riptide.Store.Memory, []},
      read: {Riptide.Store.Memory, []}
      # write: nil,
      # read: nil
    },
    interceptors: []
  }
end
