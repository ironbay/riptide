defmodule Riptide.Connection do
  @moduledoc false
  def call(pid, action, body) do
    ref = Process.monitor(pid)
    send(pid, {:riptide_call, action, body, self()})

    receive do
      {:riptide_response, "error", response} ->
        Process.demonitor(ref)
        {:error, response}

      {:riptide_response, "reply", response} ->
        Process.demonitor(ref)
        {:ok, response}

      {:DOWN, ^ref, _, _, _} ->
        {:error, :connection_crashed}
    end
  end

  # def cast(pid, action, body) do
  # end
end
