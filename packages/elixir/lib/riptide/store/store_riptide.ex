defmodule Riptide.Store.Riptide do
  @behaviour Riptide.Store

  def child_spec(opts) do
    Riptide.Store.Riptide.Supervisor.child_spec(opts)
  end

  def init(_opts) do
    :ok
  end

  def opts_name(opts), do: Keyword.get(opts, :name, :riptide)

  def mutation(merges, deletes, opts) do
    mut = %{
      merge:
        Enum.reduce(merges, %{}, fn {path, value}, collect ->
          Dynamic.put(collect, path, value)
        end),
      delete:
        Enum.reduce(deletes, %{}, fn {path, value}, collect ->
          Dynamic.put(collect, path, value)
        end)
    }

    {:ok, _} = Riptide.Connection.call(opts_name(opts), "riptide.store.mutation", mut)
    :ok
  end

  def query(paths, opts) do
    query =
      Enum.reduce(paths, %{}, fn {path, value}, collect -> Dynamic.put(collect, path, value) end)

    {:ok, result} =
      Riptide.Connection.call(
        opts_name(opts),
        "riptide.store.query",
        query
      )

    result
    |> Stream.map(fn [path, values] ->
      {
        path,
        Stream.map(values, fn [p, v] -> {p, v} end)
      }
    end)
  end
end

defmodule Riptide.Store.Riptide.Supervisor do
  use GenServer
  require Logger

  def start_link(opts) do
    opts = Enum.into(opts, %{})
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, conn} = connect(opts)

    {:ok,
     %{
       conn: conn,
       opts: opts
     }}
  end

  def handle_info({:EXIT, pid, _reason}, state = %{conn: pid}) do
    {:ok, conn} = connect(state.opts)
    {:noreply, Map.put(state, :conn, conn)}
  end

  def connect(opts) do
    Logger.info("Connecting to Riptide at #{opts.url}")
    {:ok, conn} = Riptide.Websocket.Client.start_link([url: opts.url], name: opts.name)
    {:ok, _} = Riptide.Connection.call(conn, "riptide.store.upgrade", opts.token)

    {:ok, conn}
  end
end
