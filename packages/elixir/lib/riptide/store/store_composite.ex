defmodule Riptide.Store.Composite do
  @moduledoc """
  This module provides a macro to define a store that splits up the data tree between various other stores. It is implemented via pattern matching paths that are being written or read and specifying which store to go to.

  ## Usage

  ```elixir
  defmodule Todolist.Store do
    use Riptide.Store.Composite

    @memory {Riptide.Store.Memory, []}
    @local {Riptide.Store.LMDB, directory: "data"}
    @shared {Riptide.Store.Postgres, []}

    def store(), do: [
      @memory,
      @local,
      @shared,
    ]

    # Any path starting with ["global"] is saved in a shared postgres instance
    def which_path(["global" | _rest]), do: @global

    # Any path starting with ["tmp"] is kept only in memory
    def which_path(["tmp" | _rest]), do: @memory

    # Default catch all
    def which_path(_), do: @local
  end
  ```

  ## Configuration
  ```elixir
  config :riptide,
    store: %{
      read: {Todolist.Store, []},
      write: {Todolist.Store, []},
    }
  ```
  """

  @doc """
  List of stores to initialize that are used by this module.
  """
  @callback stores() :: any
  @doc """
  For a given path, return which store to use. Take advantage of pattern matching to specify broad areas.
  """
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
