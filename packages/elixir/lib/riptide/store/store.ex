defmodule Riptide.Store do
  @callback init(opts :: any()) :: :ok | {:error, atom()}
  @callback mutation(merges :: any, deletes :: any(), opts :: any()) :: :ok | {:error, atom()}
  @callback query(paths :: any, opts :: any()) :: any

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

  def mutation(mut) do
    case Riptide.Config.riptide_store_write() do
      {store, opts} ->
        mutation(mut, store, opts)

      _ ->
        :ok
    end
  end

  def mutation(mut, store, opts) do
    merges = Dynamic.flatten(mut.merge)
    deletes = Dynamic.flatten(mut.delete)
    :ok = store.mutation(merges, deletes, opts)
  end

  def query(query) do
    {store, opts} = Riptide.Config.riptide_store_read()
    query(query, store, opts)
  end

  def query(query, store, store_opts) do
    paths = query |> Riptide.Query.flatten() |> Enum.to_list()

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

  def stream(path, opts \\ %{}) do
    {store, store_opts} = Riptide.Config.riptide_store_read()
    stream(path, opts, store, store_opts)
  end

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

  def chunk(stream, count, opts) do
    chunked = Stream.chunk_by(stream, fn {path, _value} -> Enum.at(path, count) end)

    case opts[:limit] do
      nil -> chunked
      result -> Stream.take(chunked, result)
    end
  end

  def inflate(stream) do
    stream
    |> Enum.reduce(%{}, fn
      {path, value}, collect when is_map(value) ->
        Dynamic.combine(collect, Dynamic.put(%{}, path, value))

      {path, value}, collect ->
        Dynamic.put(collect, path, value)
    end)
  end
end
