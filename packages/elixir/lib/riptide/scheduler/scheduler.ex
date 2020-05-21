defmodule Riptide.Scheduler do
  @moduledoc false
  require Logger
  use GenServer

  @root "riptide:scheduler"

  def info(task), do: Riptide.query_path!([@root, task])

  def stream(), do: Riptide.stream([@root])

  def schedule_in(offset, mod, fun, args, key \\ nil),
    do: schedule(:os.system_time(:millisecond) + offset, mod, fun, args, key)

  def schedule(timestamp, mod, fun, args, key \\ nil) do
    key = key || "SCH" <> Riptide.UUID.ascending()

    Riptide.Mutation.merge([@root, key], %{
      "key" => key,
      "timestamp" => timestamp,
      "mod" => mod,
      "fun" => fun,
      "args" => args,
      "count" => 0
    })
  end

  def cancel(task) do
    Riptide.Mutation.delete([@root, task])
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    send(self(), {:nodeup, Node.self()})
    :net_kernel.monitor_nodes(true)
    {:ok, %{scheduled: %{}, active: false}}
  end

  def handle_info({evt, _}, state) when evt in [:nodeup, :nodedown] do
    cond do
      master() == Node.self() && state.active == false ->
        Logger.info("#{__MODULE__} scheduling tasks...")

        scheduled =
          Riptide.Scheduler.stream()
          |> Stream.map(fn {task, info} ->
            now = :os.system_time(:millisecond)
            diff = max(info["timestamp"] - now, 0)
            {:ok, ref} = :timer.apply_after(diff, __MODULE__, :execute, [task])
            {task, ref}
          end)
          |> Enum.into(%{})

        {:noreply, %{scheduled: scheduled, active: true}}

      master() != Node.self() && state.active == true ->
        Logger.info("#{__MODULE__} releasing scheduled tasks")

        Enum.each(state.scheduled, fn {_task, ref} ->
          :timer.cancel(ref)
        end)

        {:noreply, %{active: false, scheduled: %{}}}

      master() == Node.self() && state.active == true ->
        {:noreply, state}

      master() != Node.self() && state.active == false ->
        {:noreply, state}
    end
  end

  def handle_call({:register, task, timestamp}, _from, state) do
    Logger.info("Registered #{task}")
    existing = Map.get(state.scheduled, task)

    if existing != nil do
      :timer.cancel(existing)
    end

    now = :os.system_time(:millisecond)
    diff = max(timestamp - now, 0)
    {:ok, ref} = :timer.apply_after(diff, __MODULE__, :execute, [task])
    {:reply, :ok, %{state | scheduled: Map.put(state.scheduled, task, ref)}}
  end

  def handle_call({:complete, task}, _from, state) do
    existing = Map.get(state.scheduled, task)

    if existing != nil do
      :timer.cancel(existing)
    end

    {:reply, :ok, %{state | scheduled: Map.delete(state.scheduled, task)}}
  end

  def complete(task) do
    :rpc.call(master(), __MODULE__, :complete_local, [task])
  end

  def complete_local(task) do
    GenServer.call(__MODULE__, {:complete, task})
  end

  def register(task, timestamp) do
    :rpc.call(master(), __MODULE__, :register_local, [task, timestamp])
  end

  def register_local(task, timestamp) do
    GenServer.call(__MODULE__, {:register, task, timestamp})
  end

  def execute(task) do
    :rpc.call(Enum.random(pool()), __MODULE__, :execute_local, [task])
  end

  def execute_local(task) do
    Logger.metadata(scheduler_task: task)

    task
    |> info()
    |> case do
      info = %{
        "mod" => mod,
        "args" => args,
        "fun" => fun,
        "timestamp" => timestamp
      } ->
        Logger.metadata(scheduler_mod: mod, scheduler_fun: fun)
        mod = String.to_atom(mod)
        fun = String.to_atom(fun)

        try do
          apply(mod, fun, args)

          cond do
            timestamp === Riptide.query_path!([@root, task, "timestamp"]) ->
              task
              |> cancel()
              |> Riptide.mutation!()

            true ->
              Riptide.merge!([@root, task, "count"], 0)
          end

          :ok
        rescue
          e ->
            :error
            |> Exception.format(e, __STACKTRACE__)
            |> Logger.error(crash_reason: {e, __STACKTRACE__})

            count = (info["count"] || 0) + 1
            Riptide.merge!([@root, task, "count"], count)

            Riptide.Retry.Basic
            |> apply(:retry, [task, count])
            |> case do
              {:delay, amount} ->
                :timer.sleep(amount)
                execute_local(task)

              :abort ->
                Riptide.delete!([@root, task])
                :abort
            end
        end

      _ ->
        {:error, :invalid_task}
    end
  end

  def master do
    pool()
    |> Enum.sort()
    |> List.first()
  end

  def pool() do
    [Node.self() | Node.list()]
  end
end
