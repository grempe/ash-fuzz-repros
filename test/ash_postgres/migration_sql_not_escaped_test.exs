defmodule Repro.AshPostgres.MigrationSqlNotEscapedTest do
  @moduledoc """
  ash-project/ash_postgres: the migration generator writes raw SQL from a
  resource into the generated migration's Elixir source without escaping it.
  When the migration is compiled, Elixir reads that SQL as the body of a string
  literal: every backslash escape is reinterpreted and `\#{` interpolates, so
  Postgres receives different SQL from the SQL the resource declares, and a
  double quote can end the literal early.

  Three sites, one cause:

    * a `check_constraint`'s `check:` (and the base filter it is combined with)
      goes into a `\"\"\"` heredoc. `escaped ~ '^\\d{4}$'` reaches Postgres
      with the DEL character (U+007F) in place of `\\d`, so the constraint
      refuses the rows it was written to accept. The snapshot records the
      declared SQL, so `mix ash.codegen --check` reports nothing pending.
    * a non-`code?` `custom_statements` `up`/`down` goes into a heredoc too.
    * an identity's unique index on a resource with `base_filter_sql` gets
      `where: "<base_filter_sql>"`, so a double quote in that SQL (a quoted
      identifier) makes the generated file invalid and `mix ash.codegen` raises.

  `custom_indexes` `where:` goes through `inspect/1` and arrives intact; the
  test that shows it is a control.

  This file defines its own resources and tables. Migrations are generated into
  a temporary directory with `AshPostgres.MigrationGenerator.generate/2` (what
  `mix ash.codegen` runs) and run inside each test's sandbox transaction, so
  the tables are rolled back afterwards.
  """
  use Repro.Case, async: false

  @bug "ash_postgres/migration-sql-not-escaped"

  defmodule Domain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource Repro.AshPostgres.MigrationSqlNotEscapedTest.Code
    end
  end

  defmodule Code do
    use Ash.Resource,
      domain: Repro.AshPostgres.MigrationSqlNotEscapedTest.Domain,
      data_layer: AshPostgres.DataLayer

    # Each Elixir string below holds a single backslash: the SQL is `\d`.
    postgres do
      table "escape_codes"
      repo Repro.Repo

      check_constraints do
        # Control: the same rule spelled without a backslash.
        check_constraint :plain, "plain_four_digits", check: "plain ~ '^[0-9]{4}$'"
        check_constraint :escaped, "escaped_four_digits", check: "escaped ~ '^\\d{4}$'"
      end

      custom_indexes do
        # Control: custom index `where:` is escaped by the generator.
        index [:escaped], name: "escape_codes_digit_index", where: "escaped ~ '\\d'"
      end

      custom_statements do
        statement :table_comment do
          up "COMMENT ON TABLE escape_codes IS 'a\\db'"
          down "COMMENT ON TABLE escape_codes IS NULL"
        end
      end
    end

    attributes do
      uuid_primary_key :id
      attribute :plain, :string, public?: true
      attribute :escaped, :string, public?: true
    end

    actions do
      defaults [:read, create: [:plain, :escaped]]
    end
  end

  defmodule QuotedDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource Repro.AshPostgres.MigrationSqlNotEscapedTest.Quoted
    end
  end

  defmodule Quoted do
    use Ash.Resource,
      domain: Repro.AshPostgres.MigrationSqlNotEscapedTest.QuotedDomain,
      data_layer: AshPostgres.DataLayer

    postgres do
      table "escape_quoted"
      repo Repro.Repo
      base_filter_sql ~S|"archived" = false|
    end

    resource do
      base_filter expr(archived == false)
    end

    attributes do
      uuid_primary_key :id
      attribute :label, :string, public?: true
      attribute :archived, :boolean, public?: true, allow_nil?: false, default: false
    end

    identities do
      identity :unique_label, [:label]
    end

    actions do
      defaults [:read, create: [:label]]
    end
  end

  defp generate(domain, name, extra \\ []) do
    dir = Path.join(System.tmp_dir!(), "#{name}_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    opts = [snapshot_path: dir, migration_path: dir, name: name, quiet: true] ++ extra

    # The generator announces each file it creates, even with `quiet: true`.
    ExUnit.CaptureIO.capture_io(:stderr, fn ->
      ExUnit.CaptureIO.capture_io(fn ->
        send(self(), {:generated, AshPostgres.MigrationGenerator.generate([domain], opts)})
      end)
    end)

    assert_received {:generated, :ok}
    {dir, opts}
  end

  # Generated and compiled once; migrated in each test's sandbox transaction.
  setup_all do
    {dir, opts} = generate(Domain, "escape_codes")

    [migration] = dir |> Path.join("*_escape_codes.exs") |> Path.wildcard()
    [{module, _}] = Elixir.Code.compile_file(migration)

    %{generator_opts: opts, migration_module: module}
  end

  setup %{migration_module: module} do
    :ok =
      Ecto.Migrator.up(Repro.Repo, 99_990_101_000_000, module, log: false, migration_lock: false)

    :ok
  end

  defp query_one(sql, params \\ []) do
    %{rows: [[value]]} = Ecto.Adapters.SQL.query!(Repro.Repo, sql, params)
    value
  end

  defp constraintdef(name) do
    query_one("SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = $1", [name])
  end

  test "control: a check without a backslash reaches Postgres as declared" do
    assert constraintdef("plain_four_digits") == "CHECK ((plain ~ '^[0-9]{4}$'::text))"
    assert {:ok, %Code{}} = Ash.create(Code, %{plain: "1234"}, authorize?: false)
    assert {:error, _} = Ash.create(Code, %{plain: "12a4"}, authorize?: false)
  end

  test "control: a custom index where clause reaches Postgres as declared" do
    assert query_one(
             "SELECT indexdef FROM pg_indexes WHERE indexname = 'escape_codes_digit_index'"
           ) =~ ~S|WHERE (escaped ~ '\d'::text)|
  end

  test "control: mix ash.codegen --check reports nothing pending", %{generator_opts: opts} do
    assert :ok = AshPostgres.MigrationGenerator.generate([Domain], opts ++ [check: true])
  end

  # ExUnit prints U+007F as `\d`, so these assertions name it explicitly.
  @tag bug: @bug, signature: ["U+007F (DEL)"]
  test "the check constraint in Postgres is the declared one" do
    definition = constraintdef("escaped_four_digits")

    refute definition =~ "\x7F",
           "the stored constraint holds U+007F (DEL) where the declared SQL has \\d"

    assert definition == ~S|CHECK ((escaped ~ '^\d{4}$'::text))|
  end

  @tag bug: @bug, signature: ["escaped_four_digits", "constraint_type: :check"]
  test "a row satisfying the declared check is accepted" do
    assert {:ok, %Code{}} = Ash.create(Code, %{escaped: "1234"}, authorize?: false)
  end

  @tag bug: @bug, signature: ["U+007F (DEL)"]
  test "a custom statement reaches Postgres as declared" do
    comment = query_one("SELECT obj_description('escape_codes'::regclass)")

    refute comment =~ "\x7F",
           "the table comment holds U+007F (DEL) where the custom statement has \\d"

    assert comment == ~S|a\db|
  end

  @tag bug: @bug, signature: ["SyntaxError", "syntax error before: archived"]
  test "an identity under a base_filter_sql with a quoted identifier generates" do
    generate(QuotedDomain, "escape_quoted")
  end
end
