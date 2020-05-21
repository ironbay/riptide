defmodule Riptide.Scheduler.Interceptor do
  @moduledoc false
  use Riptide.Interceptor

  def mutation_after(
        ["riptide:scheduler", key],
        %{merge: %{"timestamp" => timestamp}},
        _mut,
        _user
      ) do
    Riptide.Scheduler.register(key, timestamp)
    :ok
  end

  def mutation_after(["riptide:scheduler"], %{delete: deletes}, _mut, _user) do
    Enum.each(deletes, fn {task, _} -> Riptide.Scheduler.complete(task) end)
    :ok
  end
end
