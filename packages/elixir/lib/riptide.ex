defmodule Riptide do
  @internal %{internal: true}

  use Supervisor

  def start_link(opts \\ %{}) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    opts = Enum.into(opts, %{})
    Riptide.Store.init()
    Riptide.Migration.run()

    Supervisor.init(
      [
        {Riptide.Scheduler, []},
        {Riptide.Websocket.Server, opts}
      ],
      strategy: :one_for_one
    )
  end

  def query(query, state \\ @internal) do
    with :ok <- Riptide.Interceptor.query_before(query, state) do
      case Riptide.Interceptor.query_resolve(query, state) do
        nil -> {:ok, Riptide.Store.query(query)}
        result -> {:ok, result}
      end
    end
  end

  def stream(path, opts \\ %{}, state \\ @internal) do
    query = Dynamic.put(%{}, path, opts)

    with :ok <- Riptide.Interceptor.query_before(query, state) do
      Riptide.Store.stream(path, opts)
    end
  end

  def query_path!(path, opts \\ %{}, state \\ @internal) do
    {:ok, result} = query_path(path, opts, state)
    result
  end

  def query_path(path, opts \\ %{}, state \\ @internal) do
    case query(Dynamic.put(%{}, path, opts), state) do
      {:ok, result} -> {:ok, Dynamic.get(result, path)}
      result -> result
    end
  end

  def mutation!(mut) do
    case mutation(mut) do
      {:ok, result} -> result
    end
  end

  def mutation!(mut, state) do
    case mutation(mut, state) do
      {:ok, result} -> result
    end
  end

  def mutation(mut), do: mutation(mut, %{internal: true})

  def mutation(mut, state) do
    with {:ok, prepared} <- Riptide.Interceptor.mutation_before(mut, state),
         prepared <- Riptide.Interceptor.mutation_effect(prepared, state),
         :ok <- Riptide.Subscribe.broadcast_mutation(prepared),
         :ok <- Riptide.Store.mutation(prepared),
         :ok <- Riptide.Interceptor.mutation_after(prepared, state) do
      {:ok, prepared}
    end
  end

  def merge(path, value), do: mutation(Riptide.Mutation.merge(path, value))
  def merge(path, value, state), do: mutation(Riptide.Mutation.merge(path, value), state)

  def merge!(path, value) do
    {:ok, result} = mutation(Riptide.Mutation.merge(path, value))
    result
  end

  def merge!(path, value, state) do
    {:ok, result} = mutation(Riptide.Mutation.merge(path, value), state)
    result
  end

  def delete(path), do: mutation(Riptide.Mutation.delete(path))
  def delete(path, state), do: mutation(Riptide.Mutation.delete(path), state)

  def delete!(path) do
    {:ok, result} = mutation(Riptide.Mutation.delete(path))
    result
  end

  def delete!(path, state) do
    {:ok, result} = mutation(Riptide.Mutation.delete(path), state)
    result
  end
end
