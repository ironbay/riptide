defmodule Riptide.Migration do
  @moduledoc false
  require Logger
  @callback run() :: Riptide.Mutation.t() | Enum.t(Riptide.Mutation.t())
  @root "riptide:migrations"

  def all() do
    for {module, _} <- :code.all_loaded(),
        __MODULE__ in (module.module_info(:attributes)[:behaviour] || []) do
      module
    end
    |> Enum.sort()
  end

  def run() do
    now = :os.system_time(:millisecond)

    [@root]
    |> Riptide.query_path!()
    |> case do
      nil ->
        Logger.info("Migrations never run. Skipping all.")

        Riptide.merge!(
          [@root],
          all()
          |> Stream.map(fn mod -> {Atom.to_string(mod), now} end)
          |> Enum.into(%{})
        )

      migrations ->
        all()
        |> Stream.filter(fn mod -> Map.has_key?(migrations, Atom.to_string(mod)) == false end)
        |> Enum.each(fn mod ->
          Logger.info("Migration #{mod} running...")
          record = Riptide.Mutation.merge([@root, Atom.to_string(mod)], now)

          case mod.run() do
            mut = %{merge: _, delete: _} -> Stream.concat([mut], [record])
            result -> Stream.concat(result, [record])
          end
          |> Riptide.Mutation.chunk(1000)
          |> Enum.each(fn mut ->
            :ok = Riptide.Store.mutation(mut)
          end)

          Logger.info("Migration #{mod} completed successfully!")
        end)
    end

    :ok
  end
end

defmodule Riptide.Migration.Initial do
  @behaviour Riptide.Migration

  def run(), do: Riptide.Mutation.new()
end
