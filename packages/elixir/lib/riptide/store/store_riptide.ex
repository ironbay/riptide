defmodule Riptide.Store.Riptide do
  @moduledoc """
  This store forwards all mutations and queries to another Riptide instance. This is useful if you have multiple Riptide instances but want all of them to write and read from a primary node. This is comparable to web applications that write to a centralized Postgres database. Used in conjuction with `Riptide.Store.Composite` will allow you to store some data globally and some data locally.

  ## Configuration

  A primary node will only accept connections from nodes configured with the same `token`. In your primary node be sure to set the following configuration with a random token:

  ```elixir
    config :riptide, %{
      store: %{
        token: "mytoken"
      }
    }
  ```

  In your child node add the following configuration:

  ```elixir
    config :riptide, %{
      store: %{
        read: {Riptide.Store.Riptide, []},
        write: {Riptide.Store.Riptide, []},
      }
    }
  ```

  Additionally in the child nodes setup a connection to the primary node in your `application.ex`:

  ```elixir
  children = [
    {Riptide.Store.Riptide,
       [
         url: "https://primary-node:12000/socket",
         name: :riptide,
         token: "mytoken"
       ]},
    Riptide,
  ]
  ```

  This will startup a connection to the primary node before starting up Riptide locally. All data now will be written to and read from the primary node.

  ## Options

  - `:name` - name of connection to primary node, defaults to `:riptide` (optional)
  """

  @behaviour Riptide.Store

  @doc """
  Starts a connection to a remote Riptide instance

  ## Options
  - `:name` - name of connection
  - `:url` - url of remote node (required)
  - `:token` - authorization token (required)

  """
  def child_spec(opts) do
    Riptide.Store.Riptide.Supervisor.child_spec(opts)
  end

  @impl true
  def init(_opts) do
    :ok
  end

  def opts_name(opts), do: Keyword.get(opts, :name, :riptide)

  @impl true
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

  @impl true
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
  @moduledoc false
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
