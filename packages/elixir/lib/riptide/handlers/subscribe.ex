defmodule Riptide.Handler.Subscribe do
  @moduledoc false
  use Riptide.Handler

  def handle_info({:mutation, mut}, state) do
    {:reply, {"riptide.mutation", mut}, state}
  end
end
