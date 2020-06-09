defmodule Riptide.Websocket.Client do
  @moduledoc false
  use WebSockex

  def start_link(opts, client_opts \\ []) do
    opts = Enum.into(opts, %{})

    WebSockex.start_link(
      opts.url,
      __MODULE__,
      opts,
      client_opts
    )
  end

  def handle_connect(_conn, state) do
    send(self(), :connect)
    :timer.send_interval(:timer.seconds(30), self(), :ping)
    {:ok, Riptide.Processor.init(state)}
  end

  def handle_frame({:text, msg}, state) do
    case Riptide.Processor.process_data(msg, state) do
      {:reply, val, next} -> {:reply, {:text, val}, next}
      {:noreply, state} -> {:ok, state}
    end
  end

  def handle_pong(:pong, state) do
    {:ok, Map.put(state, :ping, true)}
  end

  def handle_disconnect(_conn, state) do
    {:ok, state}
  end

  def handle_info(:ping, state) do
    Process.send_after(self(), :idle, :timer.seconds(1))
    {:reply, :ping, Map.put(state, :ping, false)}
  end

  def handle_info(:idle, state = %{ping: false}) do
    {:close, state}
  end

  def handle_info(:idle, state), do: {:ok, state}

  def handle_info({:riptide_call, action, body, from}, state) do
    {:reply, data, next} = Riptide.Processor.send_call(action, body, from, state)
    {:reply, {:text, data}, next}
  end

  def handle_info({:riptide_cast, action, body}, state) do
    {:reply, data, next} = Riptide.Processor.send_cast(action, body, state)
    {:reply, {:text, data}, next}
  end

  def handle_info(msg, state) do
    case Riptide.Processor.process_info(msg, state) do
      {:reply, val, next} -> {:reply, {:text, val}, next}
      {:noreply, state} -> {:ok, state}
    end
  end
end
