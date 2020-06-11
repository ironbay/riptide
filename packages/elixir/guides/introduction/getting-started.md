# Getting Started

This guide is an intro to [Riptide](Riptide.html), the data first framework for building realtime applications in Elixir. In this guide we will learn how to setup a basic Riptide application and go over how to use its tools like queries, mutations, interceptors and more

## Adding Riptide to an application

To start off we'll generate a new Elixir application - skip this step if you already have one.

```bash
mix new todolist --sup
mkdir ./todolist/config
echo "use Mix.Config" > ./todolist/config/config.exs
```

The `--sup` ensures the application has a root supervision tree which we'll need to initialize and manage Riptide. Riptide relies on configuration so we also create a `config.exs` file for your application.

We will need to add Riptide as a dependency. Go to your `mix.exs` file and update the `deps`:

```elixir
defp deps do
  [
    {:riptide, "~> 0.4.0"},
  ]
end
```

Then install the dependency by running:

```
mix deps.get
```

Now that we have the dependency installed we can add it to our application. Go to your `lib/todolist/application.ex` and `Riptide` within the application's supervision tree:

```elixir
 def start(_type, _args) do
  children = [
    Riptide
  ]

  ...
```

That's it! You now have a barebones Riptide app ready to go. Start up the server by running:

```bash
iex -S mix
```

This will give you a running shell into your application. Let's test it out by saving some data and pulling it back out:

```elixir
iex> Riptide.merge! ["foo", "bar"], "hello world"
%Riptide.Mutation{delete: %{}, merge: %{"foo" => %{"bar" => "hello!"}}}
iex> Riptide.query_path! ["foo"]
%{"bar" => "hello!"}
```

Before we continue let's learn a bit more about the Riptide data model

## The tree data model

Before diving into building a full application, it's important to understand the data model provided by Riptide. Riptide can be configured to store it's data in various backends but always gives a consistent structure across them all.

You can think of Riptide's data model as a giant JSON tree. Here's an example of what it can look like:

```json
{
  "user:info": {
    "USRzXyccEPE3Mhg962H7lBS": {
      "id": "USRzXyccEPE3Mhg962H7lBS",
      "name": "Jack Sparrow"
    }
    ...
  },
  "user:todos": {
    "USRzXyccEPE3Mhg962H7lBS": {
      "TODzXycc3dwxU1Il2D7hN3M": {
        "id": "TODzXycc3dwxU1Il2D7hN3M",
        "text": "Capture the black pearl!"
      }
      ...
    }
  }
}
```

Here are its properties

- Data can be merged anywhere in the tree.
- Any part of the tree and all its children can be deleted
- All data under every node of a tree is sorted by ascending order
- The tree can be queried to return either all or a range of data under a path

When working with the data model we will often talk about paths, which is similar to a directory path. They're represented as a list of strings that point to a part of the tree.

In the above example the path `["user:info", "USRzXyccEPE3Mhg962H7lBS"]` would point to:

```json
{
  "id": "USRzXyccEPE3Mhg962H7lBS",
  "name": "Jack Sparrow"
}
```

The path `["user:todos", "USRzXyccEPE3Mhg962H7lBS", "TODzXycc3dwxU1Il2D7hN3M", "text"]` would point to:

```json
"Capture the black pearl!"
```

And that's it! At first this may seem primitive compared to what relational databases offer but you will see how through the tools provided by Riptide you can implement everything a modern application requires.

Additionally, representing data across the entire application, (frontend, backend, over the wire) is simple. The tree can easily be modeled with any programming language using built-in data structures (hashmaps, objects, dictionaries) or data formats (JSON).

## Updating the tree

To update the tree, you must create a `Riptide.Mutation`. It contains paths and values to merge in and/or and paths to delete. To learn how to compose complex mutations [read the full documentation here.](Riptide.Mutation.html)

Let's create a new `Todo` module that will contain helper functions to help us generate mutations.

```elixir
defmodule Todolist.Todo do
  def create(user_id, todo_id, text) do
    Riptide.Mutation.put_merge(["user:todos", user_id, todo_id], %{
      "id" => todo_id,
      "text" => text
    })
  end

  def set_done(user_id, todo_id, bool),
    do:
      Riptide.Mutation.put_merge(
        ["user:todos", user_id, todo_id, "done"],
        bool
      )

  def delete(user_id, todo_id), do: Riptide.Mutation.put_delete(["user:todos", user_id, todo_id])
end
```

We've created three functions

- `create/3` - this returns a mutation that will insert a new todo under the specified user
- `set_done/3` - this will update the `done` property of an existing todo
- `delete/2` - this will delete an existing todo

Remember, calling these functions won't actually write any data. They will only return a mutation that must then be written to your store:

```elixir
Todo.create(
  "USRzXyccEPE3Mhg962H7lBS",
  "TOD" <> Riptide.UUID.descending(),
  "My new todo!",
)
|> Riptide.mutation!()
```

You can view the documentation for the `Riptide.UUID` module - it contains useful functions to generate sortable UUIDs which work well with Riptide's sorted tree data model. We recommend prefixing all of your UUIDs for legibility.

Here is another example of creating a todo and marking it done in one transaction.

```elixir
todo_id = "TOD" <> Riptide.UUID.descending()
user_id = "USRzXyccEPE3Mhg962H7lBS"
Riptide.Mutation.combine([
  Todo.create(user_id, todo_id, "My new todo!"),
  Todo.set_done(user_id, todo_id, true),
])
|> Riptide.mutation!()
```

## Reading from the tree
