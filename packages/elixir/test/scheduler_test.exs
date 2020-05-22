defmodule Riptide.Test.Scheduler do
  use ExUnit.Case

  setup_all do
    Riptide.Config.load(Brine.Loader.Env)
    Riptide.Store.init()
    {:ok, _} = Riptide.Scheduler.start_link([])

    :ok
  end

  test "scheduler success" do
    0
    |> Riptide.Scheduler.schedule_in(__MODULE__, :success, ["hello"], "success")
    |> Riptide.mutation!()

    :timer.sleep(100)

    assert Riptide.query_path!(["test"]) == "hello"
    assert Riptide.query_path!(["riptide:scheduler", "success"]) == nil
  end

  test "scheduler fail" do
    0
    |> Riptide.Scheduler.schedule_in(__MODULE__, :fail, [], "fail")
    |> Riptide.mutation!()

    :timer.sleep(100)

    assert Riptide.query_path!(["riptide:scheduler", "fail", "count"]) == 1
  end

  test "scheduler retrigger" do
    0
    |> Riptide.Scheduler.schedule_in(__MODULE__, :retrigger, [], "retrigger")
    |> Riptide.mutation!()

    :timer.sleep(100)

    assert Riptide.query_path!(["riptide:scheduler", "retrigger"]) != nil
  end

  def success(item) do
    Riptide.merge(["test"], item)
  end

  def fail() do
    1 = 2
  end

  def retrigger() do
    0
    |> Riptide.Scheduler.schedule_in(__MODULE__, :retrigger, [], "retrigger")
    |> Riptide.mutation!()
  end
end
