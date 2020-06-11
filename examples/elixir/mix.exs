defmodule Todolist.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo_list,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Todolist.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      # {:riptide, "> 0.0.0", allow_pre: true},
      {:postgrex, "~> 0.15.4"},
      {:riptide, path: "../../packages/elixir", allow_pre: true},
      {:bcrypt_elixir, "~> 2.0"},
      {:bridge_lmdb, "~> 0.1.3"}
    ]
  end
end
