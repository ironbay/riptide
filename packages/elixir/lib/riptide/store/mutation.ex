defmodule Riptide.Mutation do
  @behaviour Access
  @moduledoc """
  A mutation represents a set of changes that can be applied to a `Riptide.Store`. This module contains functions that make it easy to compose complex mutations and combine them together.

  Mutations contains two types of operations:
  - `:merge` - A map containing the values that will be merged in - creating them if they don't already exist
  - `:delete` - A map containing the paths that should be deleted from the store


  ## Deleting
  In a mutation, the deletes are always applied first.  They are expressed as a map with a value of `1` for each path to be deleted.
  ```elixir
  iex> Mutation.put_delete(["todo:info", "001"])
  %Riptide.Mutation{
    delete: %{
      "todo:info" => %{
        "001" => 1
      }
    },
    merge: %{}
  }
  ```
  This mutation will delete everything under `["todo:info", "001]`

  ## Merging
  Merges are applied after deletes and are expressed as a map pointing to the values that should be set.

  ```elixir
  Mutation.put_merge(
    ["todo:info", "001"],
    %{
      "key" => "001",
      "text" => "Document riptide!"
    }
  )
  %Riptide.Mutation{
    delete: %{},
    merge: %{
      "todo:info" => %{
        "001" => %{
          "key" => "001",
          "text" => "Document riptide!"
        }
      }
    }
  }
  ```
  This mutation will delete everything under `["todo:info", "001]`

  ## Composing
  There are various functions in this module for composing sophisticated mutations. A good approach is to break down a complex mutation into atomic pieces for clarity and combine them together.

  Here are some examples of how they can be helpful:

  ```elixir
  Mutation.new()
  |> Mutation.put_merge(["user:info", "001", "name"], "jack")
  |> Mutation.put_merge(["user:info", "002", "name"], "john")
  |> Mutation.put_delete(["todo:info"])
  %Riptde.Mutation{
    delete: %{"todo:info" => 1},
    merge: %{
      "user:info" => %{
        "001" => %{"name" => "jack"},
        "002" => %{"name" => "john"}
      }
    }
  }
  ```

  ```elixir
  def create_user_mut(key, email) do
    Mutation.put_merge(["user:info", key], %{
      "key" => key,
      "email" => email
    })
  end

  def set_password_mut(key, password) do
    Mutation.put_merge(["user:passwords", key], Bcrypt.encrypt(password))
  end

  Mutation.combine(
    create_user_mut("001", "user@example.com"),
    set_password_mut("001", "mypassword")
  )
  %Riptde.Mutation{
    merge: %{
      "user:info" => %{
        "001" => %{
          "key" => "001",
          "email" => "user@example.com",
        }
      },
      "user:password" => %{
        "001" => "$2a$10$kj5ZhhLWIwik8uK4RJrDA.ddOEIK5VO9f4Y5FwL5D3CvVafSVXcYe"
      }
    }
  }
  ```

  ```elixir
  1..100
  |> Stream.map(fn index -> Mutation.merge(["todo:info", to_string(index)], index) end)
  |> Mutation.combine()
  %Riptide.Mutation{
    delete: %{},
    merge: %{
      "todo:info" => %{
        "1" => 1,
        "2" => 2,
        "3" => 3,
        ...
    }
  }
  ```

  """

  @typedoc "A map containing paths to be added (merge) and paths to be removed (delete)."
  @type t :: %Riptide.Mutation{merge: map, delete: map}

  @typedoc "A key-value pair representing a layer of the mutation. The key
  is a list of strings representing the path to the current layer. The value is a
  mutation, representing any deeper sub-mutations."
  @type layer :: {list(String.t()), t}

  defstruct merge: %{}, delete: %{}

  @doc ~S"""
  Creates a new mutation, optionally passing in a map for merges or deletes

  ## Examples
      iex> Riptide.Mutation.new
      %Riptide.Mutation{delete: %{}, merge: %{}}
  """
  @spec new(map, map) :: t
  def new(merge \\ %{}, delete \\ %{}) do
    %Riptide.Mutation{
      merge: merge || %{},
      delete: delete || %{}
    }
  end

  @doc """
    Creates a new mutation and puts a value to be merged
  """
  @spec put_merge(list(String.t()), any) :: t
  def put_merge(path, value), do: new() |> put_merge(path, value)

  @doc """
  Adds a merge value to the input mutation

  ## Examples
      iex> mutation = Riptide.Mutation.put_merge(["a", "b"], 1)
      iex> Riptide.Mutation.put_merge(mutation, ["a", "c"], 2)
      %Riptide.Mutation{delete: %{}, merge: %{"a" => %{"b" => 1, "c" => 2}}}
  """
  @spec put_merge(t, list(String.t()), any) :: t
  def put_merge(input, _path, value) when value == %{}, do: input
  def put_merge(input, path, value), do: Dynamic.put(input, [:merge | path], value)

  @doc """
    Creates a new mutation and puts a path to be deleted
  """
  @spec put_delete(list(String.t())) :: t
  def put_delete(path), do: new() |> put_delete(path)

  @doc ~S"""
  Adds a delete path to the input mutation

  ## Examples
      iex> Riptide.Mutation.new()
      ...> |> Riptide.Mutation.put_delete(["c"])
      %Riptide.Mutation{delete: %{"c" => 1}, merge: %{}}
  """
  @spec put_delete(t, list(String.t())) :: t
  def put_delete(input, path), do: Dynamic.put(input, [:delete | path], 1)

  @doc """
  Returns a mapping with an entry for every layer of the mutation.  The keys represent a path and the value represents the full mutation that is being merged in at that path.
  ## Examples
      iex> Riptide.Mutation.put_merge(["a", "b"], true) |> Riptide.Mutation.layers
      %{
        [] => %Riptide.Mutation{
          delete: %{},
          merge: %{
            "a" => %{
              "b" => true
            }
          }
        },
        ["a"] => %Riptide.Mutation{
          delete: %{},
          merge: %{
            "b" => true
          }
        }
      }
  """
  @spec layers(t) :: %{required(list(String.t())) => layer}
  def layers(%{merge: merge, delete: delete}) do
    merge
    |> layers(:merge)
    |> Dynamic.combine(layers(delete, :delete))
    |> Stream.map(fn {path, value} ->
      merge = Map.get(value, :merge, %{})
      delete = Map.get(value, :delete, %{})

      {path, new(merge, delete)}
    end)
    |> Enum.into(%{})
  end

  @doc false
  @spec layers(t, :merge | :delete) :: %{required(list(String.t())) => layer}
  def layers(input, type) do
    input
    |> Dynamic.layers()
    |> Enum.reduce(%{}, fn {path, value}, collect ->
      Dynamic.put(collect, [path, type], value)
    end)
  end

  @doc """
  Combines the right mutation into the left mutation and returns a singular mutation

  ## Examples
      iex> Riptide.Mutation.combine(
      ...>   %Riptide.Mutation{delete: %{}, merge: %{"a" => true}},
      ...>   %Riptide.Mutation{delete: %{}, merge: %{"b" => false}}
      ...> )
      %Riptide.Mutation{delete: %{}, merge: %{"a" => true, "b" => false}}
  """
  @spec combine(t, t) :: t
  def combine(left, right) do
    mut = combine_delete(left, right.delete)

    %{
      mut
      | merge:
          Dynamic.combine(
            mut.merge,
            right.merge
          )
    }
  end

  @doc """
  Takes a list or stream of Mutations and combines them in order to produce a single output mutation.

  ## Examples
      iex> 0..3
      ...> |> Stream.map(fn index ->
      ...>   Riptide.Mutation.put_merge(["todo:info", to_string(index)], index)
      ...> end)
      ...> |> Riptide.Mutation.combine()
      %Riptide.Mutation{delete: %{}, merge: %{"todo:info" => %{"0" => 0, "1" => 1, "2" => 2, "3" => 3}}}
  """
  @spec combine(Enum.t()) :: t
  def combine(enumerable) do
    enumerable
    |> Stream.filter(fn item -> item != nil end)
    |> Enum.reduce(new(), &combine(&2, &1))
  end

  defp combine_delete(mut, next) do
    Enum.reduce(next, mut, fn
      {key, value}, collect when value == 1 ->
        %Riptide.Mutation{
          merge:
            cond do
              is_map(collect.merge) -> Map.delete(collect.merge, key)
              true -> nil
            end,
          delete:
            case collect.delete do
              1 -> nil
              nil -> nil
              _ -> Map.put(collect.delete, key, 1)
            end
        }

      {key, value}, collect when is_map(value) ->
        %{merge: merge, delete: delete} =
          combine_delete(
            %Riptide.Mutation{
              delete:
                cond do
                  is_map(collect.delete) -> Map.get(collect.delete, key, %{})
                  true -> nil
                end,
              merge:
                cond do
                  is_map(collect.merge) -> Map.get(collect.merge, key, %{})
                  true -> nil
                end
            },
            value
          )

        %Riptide.Mutation{
          merge:
            case merge do
              result when result == %{} -> Map.delete(collect.merge, key)
              nil -> collect.merge
              _ -> Map.put(collect.merge, key, merge)
            end,
          delete:
            case delete do
              nil -> collect.delete
              _ -> Map.put(collect.delete, key, delete)
            end
        }
    end)
  end

  @doc ~S"""
  Applies the entire mutation to the input map.

  ## Example
      iex> Riptide.Mutation.apply(
      ...>  %{"b" => false},
      ...>  %{delete: %{}, merge: %{"a" => true}}
      ...> )
      %{"a" => true, "b" => false}
  """
  @spec apply(map, t) :: map
  def apply(input, mutation) do
    deleted =
      mutation.delete
      |> Dynamic.flatten()
      |> Enum.reduce(input, fn {path, _value}, collect ->
        Dynamic.delete(collect, path)
      end)

    mutation.merge
    |> Dynamic.flatten()
    |> Enum.reduce(deleted, fn {path, value}, collect ->
      Dynamic.put(collect, path, value)
    end)
  end

  @doc ~S"""
  Accepts a list and mutation, and returns a new mutation with the given
  mutation nested at the given path.

  ## Example
      iex> Riptide.Mutation.inflate(
      ...>   ["a", "b"],
      ...>   %{
      ...>     delete: %{},
      ...>     merge: %{
      ...>       "a" => 1
      ...>     }
      ...>   }
      ...> )
      ...> %Riptide.Mutation{
      ...>   delete: %{
      ...>     "a" => %{
      ...>       "b" => %{}
      ...>     }
      ...>   },
      ...>   merge: %{
      ...>    "a" => %{
      ...>      "b" => %{
      ...>        "a" => 1
      ...>      }
      ...>    }
      ...>  }
      ...> }
  """
  @spec inflate(list(String.t()), t) :: t
  def inflate(path, mut) do
    new()
    |> Dynamic.put([:merge | path], mut.merge)
    |> Dynamic.put([:delete | path], mut.delete)
  end

  @doc ~S"""
  Takes two maps and returns a mutation that could be applied to turn the
  the first map into the second.

  ## Example

    iex> Riptide.Mutation.from_diff(
    ...>	%{"a" => 1},
    ...>	%{"b" => 2}
    ...>)
    %Riptide.Mutation{delete: %{"a" => 1}, merge: %{"b" => 2}}
  """
  def from_diff(old, new) do
    old
    |> Dynamic.flatten()
    |> Enum.reduce(new(new), fn {path, value}, collect ->
      case Dynamic.get(new, path) do
        ^value -> Dynamic.delete(collect, [:merge | path])
        nil -> put_delete(collect, path)
        next -> put_merge(collect, path, next)
      end
    end)
  end

  def chunk(stream, count) do
    stream
    |> Stream.chunk_every(count)
    |> Stream.map(&Riptide.Mutation.combine/1)
  end

  @impl Access
  def fetch(struct, key), do: Map.fetch(struct, key)

  def put(struct, key, val) do
    if Map.has_key?(struct, key) do
      Map.put(struct, key, val)
    else
      struct
    end
  end

  def delete(struct, key) do
    put(struct, key, %__MODULE__{}[key])
  end

  @impl Access
  def get_and_update(struct, key, fun) when is_function(fun, 1) do
    current = fetch(struct, key)

    case fun.(current) do
      {get, update} ->
        {get, put(struct, key, update)}

      :pop ->
        {current, delete(struct, key)}

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  @impl Access
  def pop(struct, key, default \\ nil) do
    val =
      case fetch(struct, key) do
        {:ok, result} -> result
        _ -> default
      end

    updated = delete(struct, key)
    {val, updated}
  end
end
