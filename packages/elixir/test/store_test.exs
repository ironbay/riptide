defmodule Riptide.Test.Store do
  use ExUnit.Case

  test Riptide.Store.Postgres do
    Application.ensure_all_started(:postgrex)

    {:ok, pid} =
      Postgrex.start_link(
        username: "postgres",
        hostname: "localhost",
        password: "password",
        database: "postgres"
      )

    test_store(Riptide.Store.Postgres, name: pid)
  end

  test Riptide.Store.TreePostgres do
    Application.ensure_all_started(:postgrex)

    {:ok, pid} =
      Postgrex.start_link(
        username: "postgres",
        hostname: "localhost",
        password: "password",
        database: "postgres"
      )

    defmodule Tree do
      use Riptide.Tree

      branch [:root, :key], name: "extra"
    end

    test_store(Riptide.Store.TreePostgres, name: pid, tree: Tree)
  end

  test Riptide.Store.Composite do
    defmodule Store do
      use Riptide.Store.Composite

      def stores(),
        do: [
          {Riptide.Store.Memory, []}
        ]

      def which_store(_path), do: {Riptide.Store.Memory, []}
    end

    test_store(Store, [])
  end

  test Riptide.Store.Riptide do
    {:ok, pid} = Riptide.start_link()

    Application.put_env(
      :riptide,
      :store,
      %{
        write: {Riptide.Store.Memory, []},
        read: {Riptide.Store.Memory, []},
        token: "abd"
      }
    )

    Riptide.Store.Riptide.Supervisor.start_link(
      url: "http://localhost:12000/socket",
      name: :riptide,
      token: "abd"
    )

    test_store(Riptide.Store.Riptide, [])
    :ets.delete(:riptide_table)
    Process.exit(pid, :kill)
  end

  test Riptide.Store.LMDB do
    File.rm_rf("lmdb")
    test_store(Riptide.Store.LMDB, directory: "lmdb")
    File.rm_rf("lmdb")
  end

  test Riptide.Store.Memory do
    test_store(Riptide.Store.Memory, [])
    :ets.delete(:riptide_table)

    opts = [snapshot: "data.json"]
    :ok = Riptide.Store.Memory.init(opts)

    :ok =
      Riptide.Store.mutation(
        Riptide.Mutation.put_merge(["a", "b"], 1),
        Riptide.Store.Memory,
        opts
      )

    :ets.delete(:riptide_table)
    :ok = Riptide.Store.Memory.init(opts)
    assert %{"a" => %{"b" => 1}} === Riptide.Store.query(%{}, Riptide.Store.Memory, opts)
    File.rm_rf!("data.json")
    :ets.delete(:riptide_table)
  end

  test Riptide.Store.Multi,
    do: test_store(Riptide.Store.Multi, writes: [{Riptide.Store.Memory, []}])

  defp test_store(store, opts) do
    :ok = store.init(opts)
    {hh_key, hh} = Riptide.Test.Data.clean_tank()
    {gw_key, gw} = Riptide.Test.Data.pet_hammerhead()

    assert :ok =
             Riptide.Store.mutation(
               Riptide.Mutation.put_merge(["todos"], %{
                 hh_key => hh,
                 gw_key => gw
               }),
               store,
               opts
             )

    assert %{"todos" => %{^hh_key => ^hh}} =
             Riptide.Store.query(%{"todos" => %{hh_key => %{}}}, store, opts)

    assert %{"todos" => %{hh_key => %{"times" => hh["times"]}}} ==
             Riptide.Store.query(%{"todos" => %{hh_key => %{"times" => %{}}}}, store, opts)

    assert 2 =
             ["todos"]
             |> Riptide.Store.stream(%{}, store, opts)
             |> Enum.count()

    assert 1 =
             ["todos"]
             |> Riptide.Store.stream(%{min: "", limit: 1}, store, opts)
             |> Enum.count()

    assert 1 =
             ["todos"]
             |> Riptide.Store.stream(%{min: "001", max: "002"}, store, opts)
             |> Enum.count()

    assert 1 =
             ["todos"]
             |> Riptide.Store.stream(%{min: "001", max: "002"}, store, opts)
             |> Enum.count()

    assert [{^gw_key, ^gw}] =
             ["todos"]
             |> Riptide.Store.stream(%{min: "002"}, store, opts)
             |> Enum.to_list()

    assert Riptide.Store.mutation(Riptide.Mutation.put_delete(["todos", gw_key]), store, opts)

    assert %{
             "todos" => %{
               ^hh_key => ^hh
             }
           } =
             Riptide.Store.query(
               %{
                 "todos" => %{
                   hh_key => %{},
                   gw_key => %{}
                 }
               },
               store,
               opts
             )
  end
end
