# Most frameworks focus on plumbing

They ship with tools to define a REST API for your frontends, an ORM to transform objects into something your database understands, and if you're lucky, a pub/sub system for some light realtime functionality.

As your application evolves, your time becomes increasingly devoted to juggling these disparate systems and building the pipes that hold it all together.

Riptide eases this burden by taking the plumbing - how data is moved around, transformed, and saved - and making it invisible.  You're responsible purely for the logic of your application which you can implement scalably using Riptide's tooling as simple cause and effect rules.

Riptide has been enormously productive for us but choosing a framework shouldn't be done without due dilligence. To make this easier, we put together [our best arguments against Riptide](/caveats) so you can figure out if it's a good fit for your project.

* * *

## The same data model — everywhere

Traditional frameworks require you to think about your data as objects in your application, relational tables in your database, events in your message queue and all the transformations to go from one to another.

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

Data can be modified by issuing a Mutation that merges new fields or deletes existing ones. Clients can query and subscribe to parts of the tree they care about and that data will be kept in sync in realtime.


Take a deep dive into [Mutations](/mutations), [Queries](/queries), and [Stores](/stores)
* * *

## Interceptors

Interceptors leverage Elixir's pattern matching to allow you to define simple rules that trigger when matching data is written or read. Take the following Mutation that creates a new Todo.

```json
{
  "merge":{
    "todos":{
      "TOD2":{
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
  "todos":{
    "TOD2":{
      "key": "TOD2",
      "text": "Return cursed Aztec gold",
      "created": 1586068269822,
      "user": "USR1"
    }
  }
}
```

Interceptors are simple but powerful. Complex business logic can be broken down and represented as a collection of simple, independent Interceptors that are composed together to form the full application.

[Learn more about the various interceptors available in Riptide](/interceptors)

* * *

## Realtime by default

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Pretium vulputate sapien nec sagittis aliquam malesuada bibendum arcu vitae. Lobortis scelerisque fermentum dui faucibus in ornare quam viverra orci. Pellentesque id nibh tortor id aliquet lectus.

<!-- 
# Beyond REST, ORMs and Pub/Sub

Most application frameworks ship with tools to define a REST API for your frontends, an ORM to transform incoming data into something your database understands, and if you're lucky, a pub/sub system to keep everything in sync.  

This approach your energy is spent juggling these disparate systems and building the glue that holds them together. Nevermind the tools you're missing to manage your increasingly complex business logic.  

Riptide eases this pain by taking a functional approach. -->
