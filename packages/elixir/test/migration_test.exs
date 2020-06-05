defmodule Riptide.Test.Migration do
  use ExUnit.Case

  test "run" do
    Riptide.Store.init()

    defmodule Example do
      @behaviour Riptide.Migration

      def run() do
        Riptide.Mutation.put_merge(["a", "b"], 1)
      end
    end

    :ok = Riptide.Migration.run()

    assert Riptide.query_path!(["riptide:migrations", Atom.to_string(Example)]) != nil
    assert Riptide.query_path!(["a"]) == nil

    defmodule Something do
      @behaviour Riptide.Migration

      def run() do
        0..99
        |> Stream.map(fn index -> Riptide.Mutation.put_merge(["a", inspect(index)], index) end)
      end
    end

    :ok = Riptide.Migration.run()

    assert ["a"]
           |> Riptide.query_path!()
           |> Enum.count() === 100

    assert Riptide.query_path!(["riptide:migrations", Atom.to_string(Something)]) != nil
  end
end
