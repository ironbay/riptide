defmodule Riptide.Scheduler.Dispatch do
  require Logger
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :timer.send_interval(:timer.seconds(1), :poll)
    {:ok, %{active: %{}}}
  end

  def handle_info(:poll, state) do
    case active?() and Riptide.Config.riptide_scheduler() do
      true ->
        now = :os.system_time(:millisecond)

        execute =
          Riptide.Scheduler.stream()
          |> Stream.filter(fn {task, _info} -> Dynamic.get(state, [:active, task]) == nil end)
          |> Stream.filter(fn {_task, info} -> info["timestamp"] <= now end)
          |> Stream.map(fn {task, _info} -> task end)
          |> Enum.to_list()

        Enum.each(execute, fn task ->
          nodes()
          |> Enum.random()
          |> case do
            node ->
              Task.Supervisor.async_nolink(
                {Riptide.Scheduler, node},
                __MODULE__,
                :execute,
                [task]
              )
          end
        end)

        {:noreply,
         %{
           state
           | active:
               execute
               |> Stream.map(fn task -> {task, true} end)
               |> Enum.into(state.active)
         }}

      false ->
        {:noreply, state}
    end
  end

  def handle_info({_ref, {:finish, task, _result}}, state) do
    {:noreply, %{state | active: Map.delete(state.active, task)}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def execute(task) do
    {:finish, task, Riptide.Scheduler.execute(task)}
  end

  def nodes() do
    [Node.self() | Node.list()]
    |> Enum.sort()
  end

  def active?() do
    Enum.at(nodes(), 0) == Node.self()
  end
end
