defmodule Riptide.Websocket.Server do
  @moduledoc false
  @behaviour :cowboy_websocket

  def start_link(opts) do
    opts =
      [port: 12_000]
      |> Keyword.merge(opts)
      |> Enum.into(%{})

    :cowboy.start_clear(:http, [{:port, opts.port}], %{
      env: %{
        dispatch:
          :cowboy_router.compile([
            {
              :_,
              [
                {"/socket", __MODULE__, opts}
                # {"/", Riptide.Server.OK, []}
              ]
            }
          ])
      }
    })
  end

  def init(req, state) do
    {
      :cowboy_websocket,
      req,
      Riptide.Processor.init(state),
      %{
        compress: true,
        idle_timeout: :timer.hours(24)
      }
    }
  end

  def websocket_handle({:text, msg}, state) do
    case Riptide.Processor.process_data(msg, state) do
      {:reply, val, next} -> {:reply, {:text, val}, next}
      {:noreply, state} -> {:ok, state}
    end
  end

  def websocket_handle(:ping, state) do
    {:reply, :pong, state}
  end

  def websocket_info(msg, state) do
    case Riptide.Processor.process_info(msg, state) do
      {:reply, val, next} -> {:reply, {:text, val}, next}
      {:noreply, state} -> {:ok, state}
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
