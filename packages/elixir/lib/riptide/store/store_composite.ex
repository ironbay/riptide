defmodule Riptide.Store.Composite do
  @moduledoc false
  @callback stores() :: any
  @callback which_store(path :: any()) :: {atom(), any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Riptide.Store.Composite
      @behaviour Riptide.Store

      def init(_opts) do
        Enum.each(stores(), fn {store, opts} ->
          :ok = store.init(opts)
        end)
      end

      def mutation(merges, deletes, _opts) do
        groups =
          Enum.reduce(merges, %{}, fn merge = {path, value}, collect ->
            store = which_store(path)
            path = [store, :merges]
            existing = Dynamic.get(collect, path, [])
            Dynamic.put(collect, path, [merge | existing])
          end)

        groups =
          Enum.reduce(deletes, groups, fn delete = {path, value}, collect ->
            store = which_store(path)
            path = [store, :deletes]
            existing = Dynamic.get(collect, path, [])
            Dynamic.put(collect, path, [delete | existing])
          end)

        :ok =
          Enum.each(groups, fn {{store, store_opts}, data} ->
            merges = Map.get(data, :merges, [])
            deletes = Map.get(data, :deletes, [])
            store.mutation(merges, deletes, store_opts)
          end)
      end

      def query(layers, _opts) do
        groups =
          Enum.reduce(layers, %{}, fn merge = {path, value}, collect ->
            store = which_store(path)
            existing = Map.get(collect, store, [])
            Map.put(collect, store, [merge | existing])
          end)

        Stream.flat_map(groups, fn {{store, store_opts}, layers} ->
          store.query(layers, store_opts)
        end)
      end
    end
  end
end
