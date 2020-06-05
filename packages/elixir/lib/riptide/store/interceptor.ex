defmodule Riptide.Interceptor do
  @moduledoc """

  Riptide Interceptors let you define simple rules using Elixir's pattern matching that trigger conditionally when data is written or read. Each one is defined as a module that can be added to your Riptide configuration for easy enabling/disabling.

  ```elixir
  config :riptide,
  interceptors: [
    TodoList.Permissions,
    TodoList.Todo.Created,
    TodoList.Todo.Alert
  ]
  ```

  Every Interceptor in this list is called in order for every Mutation and Query processed

  ## Mutation Interceptors

  Mutation interceptors run as a mutation is being processed. The callbacks are called for each part of the paths in the mutation so you can define a pattern to match any kind of mutation. The arguments passed to them are

  - `path`: A string list representing the path where the data is being written
  - `layer`: The `merge` and `delete` that is occuring at the path
  - `mut`: The full, original mutation
  - `state`: The state of the connection which can be used to store things like the currently authed user

  ### `mutation_before`

  This runs before a mutation is written. It's best used to perform validations to make sure the data looks right, augmenting mutations with information that is known by the server only, or data denormalization. Here is an example that keeps track of the time when a Todo was marked complete

  ```elixir
  defmodule Todo.Created do
  use Riptide.Interceptor

  def mutation_before(["todos", _key], %{ merge: %{ "complete" => true }}, state) do
    {
      :merge,
      %{
        "times" => %{
            "completed" => :os.system_time(:millisecond)
        }
      }
    }
  end
  end
  ```

  The valid responses are

  - `:ok` - Returns successfully but doesn't modify anything
  - `{:error, err}` - Halts processing of interceptors and returns the error
  - `{:combine, mut}` - Combines `mut` with the input mutation before writing
  - `{:merge, map}` - Convenience version of `:combine` that merges `map` at the current path
  - `{:delete, map}` - Convenience version of `:combine` that deletes `map` at the current path

  ### `mutation_effect`

  This interceptor can be used to schedule work to be done after a mutation is successfully written. It can be used to trigger side effects like sending an email or syncing data with a third party system.

  ```elixir
  defmodule Todo.Created do
  use Riptide.Interceptor

  def mutation_before(["todos", _key], %{ merge: %{ "complete" => true }}, state) do
    {
      :merge,
      %{
        "times" => %{
            "completed" => :os.system_time(:millisecond)
        }
      }
    }
  end
  end
  ```

  The valid responses are

  - `:ok` - Returns successfully but doesn't schedule any work
  - `{fun, args}` - Calls `fun` in the current module with `args`
  - `{module, fun, args}` - Calls `fun` in `module` with `args`

  ## Query Interceptors

  Query interceptors run as a query is being processed. They can be used to allow/disallow access to certain paths or even expose third party data sources. Unlike the mutation interceptors they are called only once for each path requested by a query. The arguments passed to them are

  - `path`: A string list representing the full path where the data is being written
  - `opts`: The options for the query at this path
  - `state`: The state of the connection which can be used to store things like the currently authed user

  ### `query_before`

  This runs before data is read. A common way to use it is to control access to data

  ```elixir
  defmodule Todo.Permissions do
  use Riptide.Interceptor

  def query_before(["secrets" | _rest], _opts, state) do
    case state do
        state.user === "bad-guy" -> {:error, :auth_error}
        true -> :ok
    end
  end
  end
  ```

  The valid responses are

  - `:ok` - Returns successfully
  - `{:error, err}` - Halts processing of interceptors and returns the error

  ### `query_resolve`

  This is run before data is fetched from the store. This interceptor allows you to return data for the query and skip reading from the store. They effectively create virtual paths.

  ```elixir
  defmodule Todo.Twilio do
  use Riptide.Interceptor

  def query_resolve(["twilio", "numbers" | _rest], _opts, state) do
    TwilioApi.numbers()
    |> case do
      {:ok, result} -> Kernel.get_in(result, rest)
      {:error, err} -> {:error, err}
    end
  end
  end
  ```

  The valid responses are

  - `nil` - Skips this interceptor and continues processing
  - `any_value` - Returns `any_value` as the data under the requested path

  """
  require Logger

  @doc """
  Trigger `query_before` callback on configured interceptors for given query
  """
  def query_before(query, state),
    do: query_before(query, state, Riptide.Config.riptide_interceptors())

  @doc """
  Trigger `query_before` callback on interceptors for given query
  """
  def query_before(query, state, interceptors) do
    query
    |> query_trigger(interceptors, :query_before, [state])
    |> Enum.find_value(fn
      {_mod, nil} -> nil
      {_mod, :ok} -> nil
      {_, result} -> result
    end)
    |> case do
      nil -> :ok
      result -> result
    end
  end

  @doc """
  Trigger `query_resolve` callback on configured interceptors for given query
  """
  def query_resolve(query, state),
    do: query_resolve(query, state, Riptide.Config.riptide_interceptors())

  @doc """
  Trigger `query_resolve` callback on interceptors for given query
  """
  def query_resolve(query, state, interceptors) do
    query
    |> query_trigger(interceptors, :query_resolve, [state])
    |> Enum.find_value(fn
      {_mod, nil} -> nil
      {_, result} -> result
    end)
  end

  defp query_trigger(query, interceptors, fun, args) do
    layers = Riptide.Query.flatten(query)

    interceptors
    |> Stream.flat_map(fn mod ->
      Stream.map(layers, fn {path, opts} ->
        result = apply(mod, fun, [path, opts | args])

        if logging?() and result != nil,
          do: Logger.info("#{mod} #{fun} #{inspect(path)} -> #{inspect(result)}")

        {mod, result}
      end)
    end)
  end

  @doc """
    Trigger `mutation_effect` callback on configured interceptors for given mutation
  """
  def mutation_effect(mutation, state),
    do: mutation_effect(mutation, state, Riptide.Config.riptide_interceptors())

  @doc """
    Trigger `mutation_effect` callback on interceptors for given mutation
  """
  def mutation_effect(mutation, state, interceptors) do
    mutation
    |> mutation_trigger(interceptors, :mutation_effect, [mutation, state])
    |> Stream.map(fn {mod, result} ->
      case result do
        {fun, args} -> Riptide.Scheduler.schedule_in(0, mod, fun, args)
        {mod_other, fun, args} -> Riptide.Scheduler.schedule_in(0, mod_other, fun, args)
        _ -> Riptide.Mutation.new()
      end
    end)
    |> Riptide.Mutation.combine()
    |> Riptide.Mutation.combine(mutation)
  end

  @doc """
    Trigger `mutation_before` callback on configured interceptors for given mutation
  """
  @spec mutation_before(Riptide.Mutation.t(), any()) ::
          {:ok, Riptide.Mutation.t()} | {:error, any()}
  def mutation_before(mutation, state),
    do: mutation_before(mutation, state, Riptide.Config.riptide_interceptors())

  @doc """
    Trigger `mutation_before` callback on interceptors for given mutation
  """
  @spec mutation_before(Riptide.Mutation.t(), any(), [atom()]) ::
          {:ok, Riptide.Mutation.t()} | {:error, any()}
  def mutation_before(mutation, state, interceptors) do
    mutation
    |> mutation_trigger(interceptors, :mutation_before, [
      mutation,
      state
    ])
    |> Enum.reduce_while({:ok, mutation}, fn {mod, item}, {:ok, collect} ->
      case item do
        nil ->
          {:cont, {:ok, collect}}

        :ok ->
          {:cont, {:ok, collect}}

        {:combine, next} ->
          {:cont, {:ok, Riptide.Mutation.combine(collect, next)}}

        result = {:error, _} ->
          {:halt, result}

        _ ->
          {:halt, {:error, {:invalid_interceptor, mod}}}
      end
    end)
  end

  @doc false
  def mutation_after(mutation, state),
    do: mutation_after(mutation, state, Riptide.Config.riptide_interceptors())

  @doc false
  def mutation_after(mutation, state, interceptors) do
    mutation
    |> mutation_trigger(interceptors, :mutation_after, [
      mutation,
      state
    ])
    |> Enum.find(fn
      {_mod, :ok} -> false
      {_mod, nil} -> false
      {_mod, {:error, _}} -> true
    end)
    |> case do
      nil -> :ok
      {_mod, result} -> result
    end
  end

  defp mutation_trigger(mut, interceptors, fun, args) do
    layers = Riptide.Mutation.layers(mut)

    (interceptors ++ [Riptide.Scheduler.Interceptor])
    |> Stream.flat_map(fn mod ->
      Stream.map(layers, fn {path, data} ->
        result = apply(mod, fun, [path, data | args])

        if logging?() and result != nil,
          do: Logger.info("#{mod} #{fun} #{inspect(path)} -> #{inspect(result)}")

        {mod, result}
      end)
    end)
  end

  @doc false
  def logging?() do
    Keyword.get(Logger.metadata(), :interceptor) == true
  end

  @doc false
  def logging_enable() do
    Logger.metadata(interceptor: true)
  end

  @doc false
  def logging_disable() do
    Logger.metadata(interceptor: false)
  end

  @callback query_resolve(path :: list(String.t()), opts :: map, state :: any) ::
              {:ok, any} | {:error, term} | nil

  @callback query_before(path :: list(String.t()), opts :: map, state :: any) ::
              :ok | {:error, term} | nil

  @callback mutation_before(
              path :: list(String.t()),
              layer :: Riptide.Mutation.t(),
              mut :: Riptide.Mutation.t(),
              state :: String.t()
            ) :: :ok | {:error, term} | {:combine, Riptide.Mutation.t()} | nil

  @doc false
  @callback mutation_after(
              path :: list(String.t()),
              layer :: Riptide.Mutation.t(),
              mut :: Riptide.Mutation.t(),
              state :: String.t()
            ) :: :ok

  @callback mutation_effect(
              path :: list(String.t()),
              layer :: Riptide.Mutation.t(),
              mut :: Riptide.Mutation.t(),
              state :: String.t()
            ) :: :ok | {atom(), atom(), list()} | {atom(), list()} | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Riptide.Interceptor
      @before_compile Riptide.Interceptor
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def mutation_before(_path, _layer, _mutation, _state), do: nil
      def mutation_after(_path, _layer, _mutation, _state), do: nil
      def mutation_effect(_path, _layer, _mutation, _state), do: nil
      def query_before(_path, _opts, _state), do: nil
      def query_resolve(_path, _opts, _state), do: nil
    end
  end
end
