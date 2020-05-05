defmodule Riptide.Retry do
  @moduledoc false
  @callback retry(task :: any, count :: number()) :: any
end

defmodule Riptide.Retry.Basic do
  @moduledoc false
  @behaviour Riptide.Retry

  def retry(_task, _count) do
    {:delay, :timer.seconds(10)}
  end
end
