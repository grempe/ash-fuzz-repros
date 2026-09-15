defmodule Repro.MixProject do
  use Mix.Project

  def project do
    [
      app: :repro,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: false,
      consolidate_protocols: Mix.env() != :test,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: [setup: :test, "repros.check": :test]]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Repro.Application, []}
    ]
  end

  # Every direct dependency is pinned to the exact release the repros were
  # verified against. See README.md for the versions the bugs were found on.
  defp deps do
    [
      {:ash, "== 3.33.3"},
      {:ash_postgres, "== 2.13.1"},
      {:ash_sql, "== 0.7.5"},
      {:ash_json_api, "== 1.7.1"},
      {:ash_graphql, "== 1.11.0"},
      {:ash_lua, "== 0.2.2"},
      {:ash_ai, "== 1.0.3"},
      {:absinthe, "== 1.12.0"},
      {:absinthe_plug, "== 1.5.10"},
      {:ecto, "== 3.14.2"},
      {:ecto_sql, "== 3.14.0"},
      {:postgrex, "== 0.22.4"},
      {:spark, "== 2.7.3"},
      {:lua, "== 1.0.2"},
      {:plug, "== 1.20.3"},
      {:jason, "== 1.4.5"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
