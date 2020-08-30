defmodule Riptide.Test.Interceptor do
  defmodule Example do
    use Riptide.Interceptor

    def mutation_before(["creatures", key], %{merge: %{"key" => _}}, _mut, _state) do
      {:combine,
       Riptide.Mutation.put_merge(["creatures", key, "created"], :os.system_time(:millisecond))}
    end

    def mutation_after(["creatures", key], %{merge: %{"key" => _}}, _mut, _state) do
      Process.put(:after, true)
      :ok
    end

    def mutation_effect(["creatures", key], %{merge: %{"key" => _}}, _mut, _state),
      do: {:trigger, []}

    def trigger() do
    end

    def query_before(["denied" | _rest], _opts, _state) do
      {:error, :denied}
    end

    def query_resolve(["resolved" | path], _opts, _state) do
      {_, creature} = Riptide.Test.Data.pet_hammerhead()
      Dynamic.get(creature, path)
    end
  end

  use ExUnit.Case

  test "mutation_before" do
    {key, creature} = Riptide.Test.Data.clean_tank()

    {
      :ok,
      %{
        merge: %{
          "creatures" => %{
            ^key => %{
              "created" => _
            }
          }
        }
      }
    } =
      Riptide.Interceptor.mutation_before(
        Riptide.Mutation.put_merge(["creatures", key], creature),
        %{},
        [Example]
      )
  end

  test "mutation_after" do
    {key, creature} = Riptide.Test.Data.clean_tank()

    :ok =
      Riptide.Interceptor.mutation_after(
        Riptide.Mutation.put_merge(["creatures", key], creature),
        %{},
        [Example]
      )

    true = Process.get(:after)
  end

  test "mutation_effect" do
    {key, creature} = Riptide.Test.Data.clean_tank()

    %{
      merge: %{
        "riptide:scheduler" => %{}
      }
    } =
      Riptide.Interceptor.mutation_effect(
        Riptide.Mutation.put_merge(["creatures", key], creature),
        %{},
        [Example]
      )
  end

  test "query_resolve" do
    {_key, creature} = Riptide.Test.Data.pet_hammerhead()

    [{["resolved"], ^creature}] =
      Riptide.Interceptor.query_resolve(
        %{
          "resolved" => %{}
        },
        %{},
        [Example]
      )
  end

  test "query_before" do
    {:error, :denied} =
      Riptide.Interceptor.query_before(
        %{
          "denied" => %{}
        },
        %{},
        [Example]
      )
  end
end
