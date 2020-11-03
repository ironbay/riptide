defmodule Mix.Tasks.Riptide.Gen.Migration do
  use Mix.Task
  import Mix.Generator

  def run([name]) do
    migration_template(mod: "test")

    app =
      Mix.Project.config()
      |> Keyword.get(:app)

    file = "#{timestamp()}_#{Macro.underscore(name)}"
    path = Path.join(:code.priv_dir(app), file) |> IO.inspect()

    app_camel =
      app
      |> Atom.to_string()
      |> Macro.camelize()

    mod = "#{app_camel}.Migrations.#{Macro.camelize(name)}"

    migration_template(mod: mod)
    |> IO.puts()
  end

  def timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:migration, """
    defmodule <%= @mod %> do
      use Riptide.Migration

      def run() do
      end
    end
  """)
end
