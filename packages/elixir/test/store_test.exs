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

  test Riptide.Store.Memory, do: test_store(Riptide.Store.Memory, [])
  test Riptide.Store.Multi, do: test_store(Riptide.Store.Multi, [{Riptide.Store.Memory, []}])

  defp test_store(store, opts) do
    :ok = store.init(opts)
    {hh_key, hh} = Riptide.Test.Data.clean_tank()
    {gw_key, gw} = Riptide.Test.Data.pet_hammerhead()

    :ok =
      Riptide.Store.mutation(
        Riptide.Mutation.put_merge(["todos"], %{
          hh_key => hh,
          gw_key => gw
        }),
        store,
        opts
      )

    %{"todos" => %{^hh_key => ^hh}} =
      Riptide.Store.query(%{"todos" => %{hh_key => %{}}}, store, opts)

    2 =
      ["todos"]
      |> Riptide.Store.stream(%{}, store, opts)
      |> Enum.count()

    1 =
      ["todos"]
      |> Riptide.Store.stream(%{min: "", limit: 1}, store, opts)
      |> Enum.count()

    1 =
      ["todos"]
      |> Riptide.Store.stream(%{min: "001", max: "002"}, store, opts)
      |> Enum.count()

    1 =
      ["todos"]
      |> Riptide.Store.stream(%{min: "001", max: "002"}, store, opts)
      |> Enum.count()

    [{^gw_key, ^gw}] =
      ["todos"]
      |> Riptide.Store.stream(%{min: "002"}, store, opts)
      |> Enum.to_list()

    Riptide.Store.mutation(Riptide.Mutation.put_delete(["todos", gw_key]), store, opts)

    %{
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
