defmodule Riptide.Handler.Store do
  @moduledoc false
  use Riptide.Handler

  def handle_call("riptide.store.upgrade", token, state) do
    case Riptide.Config.riptide_store_token() do
      "" -> {:error, :token_empty, state}
      ^token -> {:reply, :ok, Map.put(state, :store, true)}
      _ -> {:error, :token_invalid, state}
    end
  end

  def handle_call("riptide.store.mutation", mut, state) do
    case state do
      %{store: true} ->
        Riptide.Mutation.new(
          mut["merge"] || %{},
          mut["delete"] || %{}
        )
        |> Riptide.Store.mutation()

        {:reply, :ok, state}

      _ ->
        {:error, :auth_invalid, state}
    end
  end

  def handle_call("riptide.store.query", query, state) do
    case state do
      %{store: true} ->
        {store, store_opts} = Riptide.Config.riptide_store_read()
        layers = Riptide.Query.flatten(query)

        result =
          layers
          |> store.query(store_opts)
          |> Stream.map(fn {path, values} ->
            [
              path,
              values
              |> Stream.map(fn {path, value} -> [path, value] end)
              |> Enum.to_list()
            ]
          end)
          |> Enum.to_list()

        {:reply, result, state}

      _ ->
        {:error, :auth_invalid, state}
    end
  end
end
