defmodule Riptide.Connection do
  @moduledoc false
  def call(pid, action, body) do
    send(pid, {:riptide_call, action, body, self()})

    receive do
      {:riptide_response, "error", response} -> {:error, response}
      {:riptide_response, "reply", response} -> {:ok, response}
    end
  end

  # def cast(pid, action, body) do
  # end
end
