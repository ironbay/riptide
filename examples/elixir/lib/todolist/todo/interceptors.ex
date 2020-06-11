defmodule Todolist.Todo.Permissions do
  use Riptide.Interceptor

  def mutation_before([], _, mut, state) do
    mut.merge
    |> Dynamic.flatten()
    |> Stream.map(fn {path, _value} ->
      merge?(path, state)
    end)
    |> Enum.any?(fn item -> item === false end)
    |> case do
      true -> {:error, :not_allowed}
      false -> :ok
    end
  end

  def merge?(_path, %{internal: true}), do: true
  def merge?(["user:todos", target | _rest], %{user: user}), do: user == target
  def merge?(_path, _state), do: false
end

defmodule Todolist.Todo.Schema do
  use Riptide.Interceptor
  import Riptide.Schema

  def mutation_before(["user:todos", _user, id], %{merge: merge = %{"id" => _}}, _mut, _state) do
    merge
    |> validate_format(Todolist.Todo)
    |> validate_required(%{
      "id" => true,
      "text" => true
    })
    |> check()
  end

  def mutation_before(["user:todos", _user, id], %{merge: merge}, _mut, _state) do
    merge
    |> validate_format(Todolist.Todo)
    |> check()
  end
end

defmodule Todolist.Todo.Created do
  use Riptide.Interceptor

  @doc """
  Appends a `created` timestamp and the `user` that owns it when the todo is first created
  """
  def mutation_before(["user:todos", user, id], %{merge: %{"id" => _}}, _mut, _state) do
    {
      :combine,
      Riptide.Mutation.put_merge(
        ["user:todos", user, id],
        %{
          "user" => user,
          "times" => %{
            "created" => :os.system_time(:millisecond)
          }
        }
      )
    }
  end
end

defmodule Todolist.Todo.Alert do
  use Riptide.Interceptor
  require Logger

  # The `mutation_effect` interceptor schedules a function to be triggered after the mutation has
  # been successfully written. It's useful for triggering side effects, like sending an SMS or
  # email
  def mutation_effect(
        ["user:todos", _user, id],
        %{merge: %{"id" => key, "text" => text}},
        _mut,
        _state
      ),
      do: {:trigger, [key, text]}

  def trigger(key, text) do
    Logger.info("Alert! Todo #{text} was created")
  end
end
