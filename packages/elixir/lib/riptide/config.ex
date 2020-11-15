defmodule Riptide.Config do
  @moduledoc false
  use Brine

  config :riptide, %{
    commands: [],
    handlers: [],
    scheduler: true,
    store: %{
      write: {Riptide.Store.Memory, []},
      read: {Riptide.Store.Memory, []},
      token: ""
      # write: nil,
      # read: nil
    },
    retry: nil,
    interceptors: []
  }
end
