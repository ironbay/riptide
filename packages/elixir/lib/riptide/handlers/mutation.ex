defmodule Riptide.Handler.Mutation do
  use Riptide.Handler

  def handle_call("riptide.mutation", mut, state) do
    (mut["merge"] || %{})
    |> Riptide.Mutation.new(mut["delete"] || %{})
    |> Riptide.mutation(state)
    |> case do
      {:ok, _mut} -> {:reply, :ok, state}
      {:error, err} -> {:error, err, state}
    end
  end
end
