# The migration generator writes raw SQL into Elixir string literals without escaping it

Versions: ash_postgres 2.13.1, ash_sql 0.7.6, ash 3.33.11, ecto_sql 3.14.0, PostgreSQL 18.6, Elixir 1.20.1 on OTP 29. Present on the default branch at `63cf7ca` (checked 2026-09-30, with ash `f3aa1b8` and ash_sql `d4fad6a`).

Found by an AI assistant working with a human while generating migrations for their own application; reproduced in a minimal project with default settings.

## Request

A resource with a check constraint whose SQL contains a backslash, then `mix ash.codegen` and `mix ecto.migrate`:

```elixir
check_constraints do
  # The SQL is: escaped ~ '^\d{4}$'
  check_constraint :escaped, "escaped_four_digits", check: "escaped ~ '^\\d{4}$'"
end
```

## Observed

The generated migration holds the SQL verbatim inside a heredoc:

```elixir
create constraint(:escape_codes, :escaped_four_digits,
         check: """
           escaped ~ '^\d{4}$'
         """
       )
```

Elixir reads `\d` in that heredoc as the escape for DEL (U+007F), so Postgres stores a different constraint. `pg_get_constraintdef` returns `CHECK ((escaped ~ '^<U+007F>{4}$'::text))`, and `Ash.create(Code, %{escaped: "1234"})` fails with `InvalidAttribute` (`constraint: "escaped_four_digits"`). `mix ash.codegen --check` reports nothing pending, because the snapshot holds the declared SQL. The same happens to every escape Elixir recognises (`\s` becomes a space, `\b` a backspace; `\A`, `\Z` and `\w` lose the backslash), and `#{...}` in the SQL is interpolated: `label <> '#{1 + 1}'` is stored as `label <> '2'`.

Two other sites share the cause:

* `custom_statements` (without `code?: true`): `up` and `down` go into an `execute("""...""")` heredoc. `COMMENT ON TABLE escape_codes IS 'a\db'` stores the comment with U+007F.
* An identity on a resource with `base_filter_sql` generates `where: "(<base_filter_sql>)"` between plain double quotes. With `base_filter_sql ~S|"archived" = false|`, `mix ash.codegen` raises `SyntaxError: syntax error before: archived` while formatting the generated file.

`custom_indexes` `where:` is written with `inspect/1` and reaches Postgres intact (`WHERE (escaped ~ '\d'::text)`).

## Expected

Postgres receives the SQL the resource declares, at every site.

## Failure point

[lib/migration_generator/operation.ex](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/migration_generator/operation.ex) at v2.13.1 interpolates the SQL with `#{...}` into the generated source:

* `AddCheckConstraint.up/1`, L1581 and L1587, and `RemoveCheckConstraint.down/1`, L1626 and L1632: `check: """` heredocs.
* `AddCustomStatement.up/1` and `down/1`, L1156 and L1168: `execute("""` heredocs.
* `AddUniqueIndex.up/1`, L1123: `where: \"#{base_filter}\"`.

On `63cf7ca` the same code is at L1737, L1743, L1782, L1788, L1247, L1259 and L1126.

## Fix direction

Escape the SQL before it is placed in the generated source. Tested against `63cf7ca`: a helper that escapes `\`, `#{` and `"""` for the heredoc sites keeps their layout, and `inspect(base_filter, printable_limit: :infinity)` for the unique index; all four failing tests then pass. `inspect/1` alone truncates strings longer than 4096 bytes. Migrations generated before a fix keep the altered SQL, and `--check` does not detect them. A pull request with this change and regression tests follows this issue.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_postgresmigration-sql-not-escaped
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/migration_sql_not_escaped_test.exs
* Run: `mix setup && mix test test/ash_postgres/migration_sql_not_escaped_test.exs` in https://github.com/grempe/ash-fuzz-repros
