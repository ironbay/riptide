defmodule Riptide.Handler.Ping do
  use Riptide.Handler

  def handle_call("riptide.ping", _, state) do
    {:reply, :os.system_time(:millisecond), state}
  end
end
