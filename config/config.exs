import Config

# The whole project runs in the :test environment (see `cli/0` in mix.exs), so
# there is a single database. DATABASE_URL overrides the local default.
config :repro,
  ecto_repos: [Repro.Repo],
  ash_domains: [Repro.Blog]

config :repro, Repro.Repo,
  url:
    System.get_env("DATABASE_URL") ||
      "postgres://postgres:postgres@localhost:5432/ash_fuzz_repros_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :ash, :include_embedded_source_by_default?, false

config :logger, level: :warning

config :ash, default_string_length_count: :codepoints
