# An integer outside the bigint range is an unconverted DBConnection.EncodeError

Versions: ash_postgres 2.13.1, ash_sql 0.7.5, ash 3.33.3, ecto 3.14.2, postgrex 0.22.4, PostgreSQL 18.6, Elixir 1.20.1 on OTP 29. Present on the default branch at `97ffea9` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

With an `:integer` attribute (stored as `bigint`): `Post |> Ash.Query.filter(score == ^9_223_372_036_854_775_808) |> Ash.read()`; the same inside `in`; `filter_input(Post, %{"score" => %{"in" => ["-99999999999999999999"]}})`; and `Ash.create(Post, %{title: "big", score: 9_223_372_036_854_775_808})`. Through AshJsonApi: `GET /posts?filter[score][eq]=9223372036854775808`.

## Observed

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (DBConnection.EncodeError) Postgrex expected an integer in -9223372036854775808..9223372036854775807, got 9223372036854775808. ..."}]}}
```
JSON:API answers 500.

## Expected

An invalid-class error: `Ash.Error.Query.InvalidFilterValue` on a read, `Ash.Error.Changes.InvalidAttribute` on a create; a 400 on JSON:API.

## Failure point

`handle_raised_error/4` has no clause for `DBConnection.EncodeError`, so it falls through to [lib/data_layer.ex#L3324](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L3324), next to the `Ecto.Query.CastError` clause at L3289.

## Notes

Ash's `:integer` type is arbitrary precision on purpose (other data layers have no 64-bit limit), so only the data layer can know the column width. `Ecto.Query.CastError` from the same query path is already converted to `InvalidFilterValue` (see the uncastable-filter-value report).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_postgresinteger-past-64-bits-unconverted
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/integer_past_64_bits_test.exs
* Run: `mix setup && mix test test/ash_postgres/integer_past_64_bits_test.exs` in https://github.com/grempe/ash-fuzz-repros
