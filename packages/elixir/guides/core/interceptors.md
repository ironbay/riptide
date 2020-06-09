# Interceptors

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
