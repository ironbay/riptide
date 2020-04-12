defmodule Riptide.Handler.Subscribe do
  use Riptide.Handler

  def handle_info({:mutation, mut}, state) do
    IO.inspect("you know im called second boy")
    {:reply, {"riptide.mutation", mut}, state}
  end
end
