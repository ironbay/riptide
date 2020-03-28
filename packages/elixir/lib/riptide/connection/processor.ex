defmodule Riptide.Processor do
  require Logger

  def init(state) do
    Map.merge(
      %{
        counter: 0,
        handlers: [],
        data: %{}
      },
      state
    )
  end

  def process_data(msg, state) do
    msg
    |> state.format.decode()
    |> case do
      {:ok,
       %{
         "type" => "cast",
         "action" => action,
         "body" => body
       }} ->
        case trigger_handlers(state, :handle_cast, [action, body, state.data]) do
          {:noreply, next} ->
            {:noreply, %{state | data: next}}

          {:reply, {action, body}, next} ->
            {:reply, cast(action, body, state), %{state | data: next}}

          nil ->
            {:noreply, state}
        end

      {:ok,
       %{
         "type" => "call",
         "key" => key,
         "action" => action,
         "body" => body
       }} ->
        case trigger_handlers(state, :handle_call, [action, body, state.data]) do
          {:reply, value, next} ->
            {:reply, reply(key, value, state), %{state | data: next}}

          {:error, error, next} ->
            {:reply, error(key, error, state), %{state | data: next}}

          {:error, error} ->
            {:reply, error(key, error, state), state}

          nil ->
            {:reply, error(key, [:not_implemented, action], state), state}
        end

      _ ->
        {:noreply, state}
    end
  end

  def process_info(msg, state) do
    case trigger_handlers(state, :handle_info, [msg, state.data]) do
      {:noreply, next} ->
        {:noreply, %{state | data: next}}

      {:reply, {action, body}, next} ->
        {:reply, cast(action, body, state), %{state | data: next}}

      nil ->
        {:noreply, state}
    end
  end

  def trigger_handlers(state, fun, args) do
    Enum.find_value(
      state.handlers ++
        [
          Riptide.Handler.Ping,
          Riptide.Handler.Mutation,
          Riptide.Handler.Query,
          Riptide.Handler.Subscribe
        ],
      fn mod ->
        try do
          apply(mod, fun, args)
        rescue
          e ->
            :error
            |> Exception.format(e, __STACKTRACE__)
            |> Logger.error(crash_reason: {e, __STACKTRACE__})

            {:error, inspect(e)}
        catch
          _, e ->
            :throw
            |> Exception.format(e, __STACKTRACE__)
            |> Logger.error(crash_reason: {e, __STACKTRACE__})

            {:error, inspect(e)}
        end
      end
    )
  end

  def reply(key, body, state) do
    %{
      type: "reply",
      key: key,
      body: body
    }
    |> format(state)
  end

  def cast(action, body, state) do
    %{
      type: "cast",
      action: action,
      body: body
    }
    |> format(state)
  end

  def error(key, body, state) do
    %{
      type: "error",
      key: key,
      body: body
    }
    |> format(state)
  end

  def format(msg, state) do
    msg
    |> state.format.encode()
    |> case do
      {:ok, result} -> result
    end
  end
end
