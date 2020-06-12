defmodule Riptide do
  @moduledoc """
  Riptide is a data first framework for building realtime applications. Riptide makes building snappy, realtime applications a breeze by letting you think purely in terms of your data and functionally about what should happen when it changes.
  """

  @internal %{internal: true}

  use Supervisor

  @doc """
  Starts a Riptide process.

  Probably should not called this directly and instead should be placed
  inside your application's root supervisor.

  ## Options

  * `:port` - Optional, will override default port of `12_000`
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(opts) do
    Riptide.Store.init()
    Riptide.Migration.run()

    Supervisor.init(
      [
        {Riptide.Scheduler, []},
        {Riptide.Websocket.Server,
         Keyword.merge(
           [handlers: Riptide.Config.riptide_handlers()],
           opts
         )}
      ],
      strategy: :one_for_one
    )
  end

  @doc """
  Pass in a query and get the results.

  Read more about query structure [here](https://riptide.ironbay.co/docs/queries). State parameter is optional and is passed to interceptors.

  ## Options
  * `:min` - Starting range of query, optional
  * `:max` - End range of query, optional
  * `:limit` - Max number of results, optional

  ## Examples
      iex> Riptide.query(%{ "todo:info" => %{} })
      %{
        "todo:info" => %{
          "todo1" => %{
            "text" => "Document riptide"
          }
        }
      }
  """
  def query(query, state \\ @internal) do
    with :ok <- Riptide.Interceptor.query_before(query, state) do
      case Riptide.Interceptor.query_resolve(query, state) do
        nil -> {:ok, Riptide.Store.query(query)}
        result -> {:ok, result}
      end
    end
  end

  @doc """
  Return a stream of values underneath a path

  ## Options
  * `:min` - Starting range of query, optional
  * `:max` - End range of query, optional
  * `:limit` - Max number of results, optional

  ## Examples
      iex> Riptide.stream(["todo:info"]) |> Enum.take(1)
      [
        %{"todo1", %{ "text" => "Document riptide" }}
      ]
  """
  def stream(path, opts \\ %{}, state \\ @internal) do
    query = Dynamic.put(%{}, path, opts)

    with :ok <- Riptide.Interceptor.query_before(query, state) do
      Riptide.Store.stream(path, opts)
    end
  end

  @doc """
    The same as `query_path/3` but raises an exception if it fails
  """
  def query_path!(path, opts \\ %{}, state \\ @internal) do
    {:ok, result} = query_path(path, opts, state)
    result
  end

  @doc """
  Return data under a specific path

  ## Options
  * `:min` - Starting range of query, optional
  * `:max` - End range of query, optional
  * `:limit` - Max number of results, optional
  """
  def query_path(path, opts \\ %{}, state \\ @internal) do
    case query(Dynamic.put(%{}, path, opts), state) do
      {:ok, result} -> {:ok, Dynamic.get(result, path)}
      result -> result
    end
  end

  @doc """
    The same as `mutation/2` but raises an exception if it fails
  """
  def mutation!(mut, state \\ @internal) do
    case mutation(mut, state) do
      {:ok, result} -> result
    end
  end

  @doc """
  Apply a mutation.
  This will do following steps in order
  1. Trigger `c:Riptide.Interceptor.mutation_before/4`
  2. Trigger `c:Riptide.Interceptor.mutation_effect/4`
  3. Broadcast mutation to interested processes
  4. Write mutation to stores
  5. Trigger `c:Riptide.Interceptor.mutation_after/4`

  ## Examples
      iex> mut = Riptide.Mutation.put_merge(["foo", "bar"], "hello")
      iex> Riptide.mutation(mut)
      {:ok, %{
        merge: %{
          "foo" => %{
            "bar" => "hello
          }
        },
        delete: %{}
      }}
  """
  @spec mutation(Riptide.Mutation.t(), any()) :: {:ok, Riptide.Mutation.t()} | {:error, any()}
  def mutation(mut, state \\ @internal) do
    with {:ok, prepared} <- Riptide.Interceptor.mutation_before(mut, state),
         prepared <- Riptide.Interceptor.mutation_effect(prepared, state),
         :ok <- Riptide.Subscribe.broadcast_mutation(prepared),
         :ok <- Riptide.Store.mutation(prepared),
         :ok <- Riptide.Interceptor.mutation_after(prepared, state) do
      {:ok, prepared}
    end
  end

  @doc """
  Convience method to apply a mutation that merges a single value

  ## Examples
      iex> Riptide.merge(["foo", "bar"], "hello")
      {:ok, %{
        merge: %{
          "foo" => %{
            "bar" => "hello
          }
        },
        delete: %{}
      }}
  """
  def merge(path, value, state \\ @internal),
    do:
      path
      |> Riptide.Mutation.put_merge(value)
      |> mutation(state)

  @doc """
    The same as `merge/3` but raises an exception if it fails
  """
  def merge!(path, value, state \\ @internal) do
    {:ok, result} = merge(path, value, state)
    result
  end

  @doc """
  Convience method to apply a mutation that deletes a single path

  ## Examples
      iex> Riptide.delete(["foo", "bar"])
      {:ok, %{
        delete: %{
          "foo" => %{
            "bar" => 1
          }
        },
        delete: %{}
      }}
  """
  def delete(path, state \\ @internal),
    do:
      path
      |> Riptide.Mutation.put_delete()
      |> mutation(state)

  @doc """
    The same as `delete/2` but raises an exception if it fails
  """
  def delete!(path, state \\ @internal) do
    {:ok, result} = delete(path, state)
    result
  end
end
