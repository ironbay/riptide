defmodule Ocean.Permissions do
  use Riptide.Interceptor

  def mutation_before([], _layer, mut, %{internal: true}), do: :ok

  def mutation_before([], _layer, mut, state) do
    # mut
    # |> Riptide.Mutation.layers()
    # |> Enum.any?(fn
    #   {["creatures" | _], _} -> false
    #   {path, layer} -> false
    # end)
    # |> case do
    #   true -> :ok
    #   false -> {:error, :not_allowed}
    # end
  end
end
