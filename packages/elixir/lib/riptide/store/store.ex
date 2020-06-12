defmodule Riptide.Store do
  @moduledoc """
  Riptide stores are where data can be written to and read from. This module provides a behavior that can be implemented to integrate any data store with Riptide. Regardless of the underlying store, Riptide consistently provides [a tree data model](getting-started.html#the-tree-data-model)

  The following stores are available out of the box. Visit their
  - `Riptide.Store.Composite`
  - `Riptide.Store.LMDB`
  - `Riptide.Store.Memory`
  - `Riptide.Store.Multi`
  - `Riptide.Store.Postgres`
  - `Riptide.Store.Riptide`

  ## Configuration
  Stores can be assigned via configuration. Riptide supports specifying different stores for reads and for writes although typically you will configure the same for both:

  ```elixir
  config :riptide,
    store: %{
      read: {Riptide.Store.MyStore, option1: "test"},
      write: {Riptide.Store.MyStore, option1: "test"}
    }
  ```

  """
  @callback init(opts :: any()) :: :ok | {:error, atom()}
  @callback mutation(merges :: any, deletes :: any(), opts :: any()) :: :ok | {:error, atom()}
  @callback query(paths :: any, opts :: any()) :: any

  @doc """
  Initialize all configured stores
  """
  def init() do
    [
      Riptide.Config.riptide_store_read(),
      Riptide.Config.riptide_store_write()
    ]
    |> Enum.uniq()
    |> Enum.map(fn
      {store, opts} -> :ok = store.init(opts)
      _ -> :ok
    end)
  end

  @doc """
  Apply mutation to configured write store. Does not trigger interceptors.
  """
  def mutation(mut) do
    case Riptide.Config.riptide_store_write() do
      {store, opts} ->
        mutation(mut, store, opts)

      _ ->
        :ok
    end
  end

  @doc """
  Apply mutation to specified store with opts. Does not trigger interceptors.
  """
  def mutation(mut, store, opts) do
    merges = Dynamic.flatten(mut.merge)
    deletes = Dynamic.flatten(mut.delete)
    :ok = store.mutation(merges, deletes, opts)
  end

  @doc """
  Processes query with configured read store. Does not trigger interceptors.
  """
  def query(query) do
    {store, opts} = Riptide.Config.riptide_store_read()
    query(query, store, opts)
  end

  @doc """
  Processes query with specified store with opts. Does not trigger interceptors.
  """
  def query(query, store, store_opts) do
    paths =
      query
      |> Riptide.Query.flatten()
      |> Enum.to_list()

    paths
    |> store.query(store_opts)
    |> Stream.flat_map(fn {path, stream} ->
      opts = Dynamic.get(query, path)
      count = Enum.count(path)

      stream
      |> chunk(count, opts)
      |> Stream.flat_map(fn values -> values end)
    end)
    |> inflate()

    # paths
    # |> Enum.reduce(%{}, fn {path, _}, collect ->
    #   value = Dynamic.get(result, path)
    #   Dynamic.put(collect, path, value)
    # end)
  end

  @doc """
  Stream data from configured read store.
  """
  def stream(path, opts \\ %{}) do
    {store, store_opts} = Riptide.Config.riptide_store_read()
    stream(path, opts, store, store_opts)
  end

  @doc """
  Stream data from specified read store with opts.
  """
  def stream(path, opts, store, store_opts) do
    count = Enum.count(path)

    [{path, opts}]
    |> store.query(store_opts)
    |> Stream.flat_map(fn {_path, stream} -> stream end)
    |> chunk(count, opts)
    |> Stream.map(fn values ->
      values
      |> Stream.map(fn {path, value} ->
        {Enum.drop(path, count), value}
      end)
    end)
    |> Stream.flat_map(&inflate/1)
  end

  # def chunk(stream, query) do
  #   chunked =
  #     Stream.chunk_while(stream, {nil, []}, fn {prefix, path, value}, {current, values} ->
  #       cond do
  #         current == nil -> {:cont, {prefix, [{path, value}]}}
  #         current == prefix -> {:cont, {prefix, [{path, value} | values]}}
  #         current !== prefix -> {:cont, {current, values}, {prefix, [{path, value}]}}
  #       end
  #     end)

  #   case opts[:limit] do
  #     nil -> chunked
  #     result -> Stream.take(chunked, result)
  #   end
  # end

  defp chunk(stream, count, opts) do
    chunked = Stream.chunk_by(stream, fn {path, _value} -> Enum.at(path, count) end)

    case opts[:limit] do
      nil -> chunked
      result -> Stream.take(chunked, result)
    end
  end

  defp inflate(stream) do
    stream
    |> Enum.reduce(%{}, fn
      {path, value}, collect when is_map(value) ->
        Dynamic.combine(collect, Dynamic.put(%{}, path, value))

      {path, value}, collect ->
        Dynamic.put(collect, path, value)
    end)
  end
end
