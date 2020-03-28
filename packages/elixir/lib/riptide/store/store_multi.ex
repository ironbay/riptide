defmodule Riptide.Store.Multi do
  @behaviour Riptide.Store
  def init(stores) do
    Enum.each(stores, fn {store, opts} ->
      :ok = store.init(opts)
    end)
  end

  def mutation(merges, deletes, stores) do
    Enum.each(stores, fn {store, opts} ->
      :ok = store.mutation(merges, deletes, opts)
    end)
  end

  def query(paths, stores) do
    {store, opts} = Enum.at(stores, 0)
    store.query(paths, opts)
  end
end
