defmodule Riptide.Scheduler.Interceptor do
  use Riptide.Interceptor

  # def mutation_after(
  #       ["riptide:scheduler", key],
  #       %{merge: %{"timestamp" => timestamp}},
  #       _mut,
  #       _user
  #     ) do
  #   Riptide.Scheduler.schedule(key, timestamp)
  #   :ok
  # end
end
