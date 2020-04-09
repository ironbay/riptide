defmodule Riptide.MixProject do
  use Mix.Project

  def project do
    [
      app: :riptide,
      version: "0.2.2",
      description: "Framework for building realtime applications",
      package: [
        maintainers: ["thdxr", "ironbay"],
        licenses: ["MIT"],
        links: %{}
      ],
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Riptide.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.7"},
      {:jason, "~> 1.1"},
      {:dynamic, "~> 0.1.2"},
      {:brine, "~> 0.2.2"},
      {:bridge_lmdb, "~> 0.1.1", optional: true},
      {:postgrex, "~> 0.15.3", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end
end
