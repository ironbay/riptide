# Example mutation that would trigger these interceptors
#
# %{
#   merge: %{
#     "todos" => %{
#       "001" => %{
#         "key" => "001",
#         "name" => "Great White Shark"
#       }
#     }
#   },
#  delete: %{}
# }

defmodule TodoList.Todo.Created do
  use Riptide.Interceptor

  # Appends a `created` timestamp when the todo is first created
  def mutation_before(["todos", key], %{merge: %{"key" => _}}, _mut, _state) do
    {
      :combine,
      Riptide.Mutation.put_merge(["todos", key, "created"], :os.system_time(:millisecond))
    }
  end
end

defmodule TodoList.Todo.Alert do
  use Riptide.Interceptor
  require Logger

  # The `mutation_effect` interceptor schedules a function to be triggered after the mutation has
  # been successfully written. It's useful for triggering side effects, like sending an SMS or
  # email
  def mutation_effect(
        ["todos", key],
        %{merge: %{"key" => key, "name" => name}},
        _mut,
        _state
      ),
      do: {:trigger, [key, name]}

  def trigger(key, name) do
    Logger.info("Alert! Todo #{name} was created")
  end
end
