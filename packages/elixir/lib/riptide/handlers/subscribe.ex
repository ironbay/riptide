defmodule Riptide.Handler.Subscribe do
  use Riptide.Handler

  def handle_info({:mutation, mut}, state) do
    {:reply, {"riptide.mutation", mut}, state}
  end
end
