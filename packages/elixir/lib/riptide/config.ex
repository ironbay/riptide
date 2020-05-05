defmodule Riptide.Config do
  @moduledoc false
  use Brine

  config :riptide, %{
    commands: [],
    handlers: [],
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
