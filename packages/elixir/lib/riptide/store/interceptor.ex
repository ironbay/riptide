defmodule Riptide.Interceptor do
  require Logger

  def query_before(query, state),
    do: query_before(query, state, Riptide.Config.riptide_interceptors())

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

  def mutation_effect(mutation, state),
    do: mutation_effect(mutation, state, Riptide.Config.riptide_interceptors())

  def mutation_effect(mutation, state, interceptors) do
    mutation
    |> mutation_trigger(interceptors, :mutation_effect, [mutation, state])
    |> Stream.map(fn {mod, result} ->
      case result do
        {fun, args} -> Riptide.Scheduler.schedule_in(mod, fun, args, 0)
        {mod_other, fun, args} -> Riptide.Scheduler.schedule(mod_other, fun, args, 0)
        _ -> Riptide.Mutation.new()
      end
    end)
    |> Riptide.Mutation.combine()
    |> Riptide.Mutation.combine(mutation)
  end

  def mutation_before(mutation, state),
    do: mutation_before(mutation, state, Riptide.Config.riptide_interceptors())

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

  def mutation_after(mutation, state),
    do: mutation_after(mutation, state, Riptide.Config.riptide_interceptors())

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

  def query_resolve(query, state),
    do: query_resolve(query, state, Riptide.Config.riptide_interceptors())

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

  def logging?() do
    Keyword.get(Logger.metadata(), :interceptor) == true
  end

  def logging_enable() do
    Logger.metadata(interceptor: true)
  end

  def logging_disable() do
    Logger.metadata(interceptor: false)
  end

  @callback query_resolve(path :: list(String.t()), opts :: map, state :: any) ::
              {:ok, any} | {:error, term} | nil

  @callback query_before(path :: list(String.t()), opts :: map, state :: any) ::
              {:ok, any} | {:error, term} | nil

  @callback mutation_before(
              path :: list(String.t()),
              layer :: Riptide.Mutation.t(),
              mut :: Riptide.Mutation.t(),
              state :: String.t()
            ) :: :ok | {:error, term} | {:combine, Riptide.Mutation.t()}

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
            ) :: :ok | {atom(), atom(), list(String.t())} | {atom(), list(String.t())}

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
