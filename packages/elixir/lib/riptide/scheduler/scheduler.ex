defmodule Riptide.Scheduler do
  @moduledoc false
  require Logger
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_) do
    Supervisor.init(
      [
        {Task.Supervisor, name: __MODULE__},
        Riptide.Scheduler.Dispatch
      ],
      strategy: :one_for_one
    )
  end

  @root "riptide:scheduler"

  def info(task), do: Riptide.query_path!([@root, task])

  def stream(), do: Riptide.stream([@root])

  def cancel(task) do
    Riptide.Mutation.delete([@root, task])
  end

  def schedule_in(mod, fun, args, offset, key \\ nil),
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

  def execute(task) do
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
              Riptide.delete!([@root, task])

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
                execute(task)

              :abort ->
                Riptide.delete!([@root, task])
                :abort
            end
        end

      _ ->
        {:error, :invalid_task}
    end
  end
end
