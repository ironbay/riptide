defmodule Riptide.Store.Multi do
  @moduledoc """
  A proxy store that will write data to multiple stores.

  ## Configuration

  ```elixir
  config :riptide,
    store: %{
      read: {Riptide.Store.Memory, []},
      write: {Riptide.Store.Multi, stores: [
        {Riptide.Store.LMDB, directory: "data"},
        {Riptide.Store.Memory, []}
      ]}
    }

  ```

  ## Options
  - `:stores` - list of stores to write data to (required)
  """

  @behaviour Riptide.Store

  @impl true
  def init(opts) do
    opts
    |> opts_writes()
    |> Enum.each(fn {store, opts} -> :ok = store.init(opts) end)
  end

  defp opts_writes(opts) do
    Keyword.get(opts, :writes, [])
  end

  @impl true
  def mutation(merges, deletes, opts) do
    opts
    |> opts_writes()
    |> Enum.each(fn {store, store_opts} ->
      :ok = store.mutation(merges, deletes, store_opts)
    end)
  end

  @impl true
  def query(_paths, _opts) do
    []
  end
end
