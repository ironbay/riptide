defmodule Riptide.Retry do
  @callback retry(task :: any, count :: number()) :: any
end

defmodule Riptide.Retry.Basic do
  @behaviour Riptide.Retry

  def retry(_task, _count) do
    {:delay, :timer.seconds(10)}
  end
end
