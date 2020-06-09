# Overview

Riptide is a data first framework for building realtime applications. Riptide makes building snappy, realtime applications a breeze by letting you think purely in terms of your data and functionally about what should happen when it changes. [Build your first Riptide application](getting-started.html).

## One data model — everywhere

Traditional frameworks require you to think about your data in numerous ways:

- Objects in your application
- Relational tables in your database
- Events in your message queue

Riptide represents all of your data as one big tree no matter where you are: server, client or database

```json
{
  "users": {
    "USR1": {
      "key": "USR1",
      "name": "Jack Sparrow",
    },
    "USR2": {...},
    "USR3": {...}
  },
  "todos": {
    "TOD1": {
      "key": "TOD1",
      "user": "USR1",
      "created": 1586068269822,
      "text": "Find the Black Pearl",
    }
    ...
  }
}
```

Take a deep dive into [Mutations](Riptide.Mutation.html), [Queries](/queries), and [Stores](/stores)

## Composable logic

Riptide Interceptors let you define simple rules using Elixir's pattern matching that trigger conditionally when data is written or read. Take the following Mutation that creates a new Todo.

```json
{
  "merge": {
    "todos": {
      "TOD2": {
        "key": "TOD2",
        "text": "Return cursed Aztec gold"
      }
    }
  }
}
```

It will trigger the following Interceptor which effectively says whenever a Todo is created, record the current time and user who created it.

```elixir
defmodule Todo.Created do
  use Riptide.Interceptor

  def before_mutation(
        # Match path being written to
        ["todos", _key],
        # Match fields being merged
        %{ merge: %{ "key" => _ }},
        # Full mutation
        _full,
        # Connection state
        state
      ) do
    {
      :merge,
      %{
        "created" => :os.system_time(:millisecond),
        "user" => state.user
      }
    }
  end
end
```

This results in the following data being written

```json
{
  "todos": {
    "TOD2": {
      "key": "TOD2",
      "text": "Return cursed Aztec gold",
      "created": 1586068269822,
      "user": "USR1"
    }
  }
}
```

Interceptors are simple but powerful. Even the most complex business logic can be broken down into a collection of composable, independent and easily digestable Interceptors.

[Learn more about the various interceptors available in Riptide](/docs/interceptors)

## Realtime by default

Riptide takes care of shipping data around and ensuring all observers are kept up to date with the latest changes. This happens automatically - there's no pub/sub system to setup or event triggers and handlers to define.

```javascript
// React example
Riptide.remote.query_path(["todos"], { subscribe: true })

function render() {
  return (
    <ul>
    {
      Riptide.local
        .query_values(["todos"])
        .map(item => (
          <li key={item.key}>{item.text}</li>
        ))
    }
    </ul>;
  )
}
```

Instead of being an after thought, 100% of the UIs you build will be realtime by default.
