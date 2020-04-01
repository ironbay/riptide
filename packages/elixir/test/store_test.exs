defmodule Riptide.Test.Store do
  use ExUnit.Case

  # test Riptide.Store.Postgres do
  #   Application.ensure_all_started(:postgrex)

  #   {:ok, pid} =
  #     Postgrex.start_link(
  #       username: "postgres",
  #       hostname: "localhost",
  #       password: "password",
  #       database: "postgres"
  #     )

  #   test_store(Riptide.Store.Postgres, name: pid)
  # end

  test Riptide.Store.LMDB do
    File.rm_rf("lmdb")
    test_store(Riptide.Store.LMDB, directory: "lmdb")
    File.rm_rf("lmdb")
  end

  test Riptide.Store.Memory, do: test_store(Riptide.Store.Memory, [])
  test Riptide.Store.Multi, do: test_store(Riptide.Store.Multi, [{Riptide.Store.Memory, []}])

  defp test_store(store, opts) do
    :ok = store.init(opts)
    {hh_key, hh} = Riptide.Test.Data.hammerhead()
    {gw_key, gw} = Riptide.Test.Data.gw()

    :ok =
      Riptide.Store.mutation(
        Riptide.Mutation.merge(["creatures"], %{
          hh_key => hh,
          gw_key => gw
        }),
        store,
        opts
      )

    %{"creatures" => %{^hh_key => ^hh}} =
      Riptide.Store.query(%{"creatures" => %{hh_key => %{}}}, store, opts)

    2 =
      ["creatures"]
      |> Riptide.Store.stream(%{}, store, opts)
      |> Enum.count()

    1 =
      ["creatures"]
      |> Riptide.Store.stream(%{limit: 1}, store, opts)
      |> Enum.count()

    [{^gw_key, ^gw}] =
      ["creatures"]
      |> Riptide.Store.stream(%{min: "002"}, store, opts)
      |> Enum.to_list()

    Riptide.Store.mutation(Riptide.Mutation.delete(["creatures", gw_key]), store, opts)

    %{
      "creatures" => %{
        ^hh_key => ^hh
      }
    } =
      Riptide.Store.query(
        %{
          "creatures" => %{
            hh_key => %{},
            gw_key => %{}
          }
        },
        store,
        opts
      )
  end
end
