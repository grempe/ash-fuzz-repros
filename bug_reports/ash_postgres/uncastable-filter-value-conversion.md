# Ecto.Query.CastError is converted only where a rescue exists, and Ecto.SubQueryError is never unwrapped

Versions: ash_postgres 2.13.1, ash_sql 0.7.5, ash 3.33.3, ecto 3.14.2, postgrex 0.22.4, PostgreSQL 18.6, Elixir 1.20.1 on OTP 29. Present on the default branch at `97ffea9` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

With a UUID primary key and `query = Ash.Query.filter(Post, id == "not-a-uuid")`, `Ash.read(query)` returns `{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}}`. These do not:

| Case | Call | Result |
|---|---|---|
| a | `Ash.count(query)`, `Ash.exists(query)`, `Ash.aggregate(query, {:m, :max, field: :inserted_at})` | raises `Ecto.Query.CastError` |
| b | `query \|> Ash.Query.limit(1) \|> Ash.count()` | raises `Ecto.SubQueryError` |
| c | `Post \|> Ash.Query.load(comments: Comment \|> Ash.Query.filter(id == "not-a-uuid") \|> Ash.Query.limit(1)) \|> Ash.read()` with two or more posts | raises `Ash.Error.Unknown` wrapping `Ecto.SubQueryError` |
| d | `Post \|> Ash.Query.filter_input(%{comments: %{id: %{eq: "not-a-uuid"}}}) \|> Ash.read(page: [limit: 5])` | `{:error, %Ash.Error.Unknown{}}` wrapping `Ecto.SubQueryError` |
| e | AshJsonApi `PATCH /posts/not-a-uuid` | 500; `Ash.Error.Unknown` wrapping `Ecto.SubQueryError` from `update_query/4` |

With a single parent, case c converts cleanly, and `Ash.bulk_update/4` filtered by the bad id converts cleanly too (the error is a bare `CastError` there).

## Observed

```
** (Ecto.Query.CastError) deps/ash_sql/lib/expr.ex:1960: value `"not-a-uuid"` in `where` cannot be cast to type #Ash.Type.UUID.EctoType<[]> in query: ...
```
and, for the subquery cases:
```
** (Ecto.SubQueryError) the following exception happened when compiling a subquery.
    ** (Ecto.Query.CastError) ... value `"not-a-uuid"` in `where` cannot be cast ...
```
The `Ash.DataLayer` behaviour declares `{:ok, _} | {:error, _}` for `run_query`, `run_aggregate_query`, `run_aggregate_query_with_lateral_join` and `run_query_with_lateral_join`, so cases a to c also violate the callback contract. Downstream, ash_lua `operation = "count"` and `"exists"` return the raw cast error text and AshGraphql answers "Something went wrong" for the c and d shapes; those are effects of this bug, not separate ones.

## Expected

`{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}}` in every case, as on a plain read.

## Failure point

[lib/data_layer.ex](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex): `run_query/2` rescues at L925-L927; `run_aggregate_query/3` (L977), `run_query_with_lateral_join/4` (L1116, raise at L1148) and `run_aggregate_query_with_lateral_join/5` (L996, not exercised by a test) have no rescue; `handle_raised_error/4` converts a bare `Ecto.Query.CastError` at L3289 and sends `Ecto.SubQueryError` to the generic clause at L3324, from `run_query/2` (6d) and `update_query/4` (L1840, rescue at L1959, 6e).

## Notes

The GraphQL `{ count }` and JSON:API `page[count]=true` variants reach the count query only with `config :ash, :disable_async?, true`; the tests set it for those two cases. Related: an integer value outside the 64-bit range fails in the same function for a different exception, `DBConnection.EncodeError` (separate report). Also observed: the `InvalidFilterValue` produced by the working conversion carries the whole Ecto query as `context`, so `Exception.message/1` on it prints the query struct including `__ash_bindings__` with the actor and tenant.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_postgresuncastable-filter-value-conversion
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/uncastable_filter_value_conversion_test.exs
* Run: `mix setup && mix test test/ash_postgres/uncastable_filter_value_conversion_test.exs` in https://github.com/grempe/ash-fuzz-repros
