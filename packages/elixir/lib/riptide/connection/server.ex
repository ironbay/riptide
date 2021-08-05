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
                {"/socket", __MODULE__, opts},
                {"/", Riptide.Websocket.OK, []}
              ]
            }
          ])
      }
    })
  end

  def init(req, state) do
    state = Riptide.Processor.init(state)
    {:noreply, state} = Riptide.Processor.process_info({:connect, req}, state)

    {
      :cowboy_websocket,
      req,
      state,
      %{
        compress: true,
        idle_timeout: :timer.hours(24)
      }
    }
  end

  def websocket_init(state) do
    :timer.send_interval(:timer.seconds(10), self(), :gc)
    {:ok, state}
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

  def handle_info({:riptide_call, action, body, from}, state) do
    {:reply, data, next} = Riptide.Processor.send_call(action, body, from, state)
    {:reply, {:text, data}, next}
  end

  def handle_info({:riptide_cast, action, body}, state) do
    {:reply, data, next} = Riptide.Processor.send_cast(action, body, state)
    {:reply, {:text, data}, next}
  end

  def websocket_info(:gc, state) do
    :erlang.garbage_collect(self())
    {:ok, state}
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

defmodule Riptide.Websocket.OK do
  @moduledoc false
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
    reply =
      :cowboy_req.reply(
        200,
        request
      )

    {:ok, reply, state}
  end

  def terminate(_reason, _request, _state), do: :ok
end
