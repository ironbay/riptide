defmodule Riptide.Store.Benchmark do
  require Logger

  def run(store, opts) do
    store.init(opts)
    range_count = 100_000
    range = range_count..(range_count * 2)

    time("Write #{range_count} values", fn ->
      range
      |> Stream.map(fn item ->
        Riptide.Mutation.merge(["large", inspect(item)], %{
          "key" => item,
          "created" => :os.system_time(:millisecond)
        })
      end)
      |> Riptide.Mutation.chunk(1000)
      |> Enum.each(fn mut -> Riptide.Store.mutation(mut, store, opts) end)
    end)

    read_count = 10_000

    time("Read #{read_count} consecutive values", fn ->
      Riptide.Store.query(
        %{"large" => %{limit: read_count}},
        store,
        opts
      )
    end)

    time("Read #{read_count} random values", fn ->
      Riptide.Store.query(
        range
        |> Enum.take_random(read_count)
        |> Enum.reduce(%{}, fn item, collect ->
          Dynamic.put(collect, ["large", inspect(item)], %{limit: 10})
        end),
        store,
        opts
      )
    end)
  end

  def time(name, fun) do
    Logger.info("Starting #{name}")
    now = :os.system_time(:millisecond)
    fun.()
    result = :os.system_time(:millisecond) - now
    Logger.info(name <> ": " <> inspect(result) <> "ms")
  end
end
