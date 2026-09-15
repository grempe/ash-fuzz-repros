# first: 0 and last: 0 are an unrendered error

Versions: ash_graphql 1.11.0, absinthe 1.12.0, absinthe_plug 1.5.10, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `fd31401` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`listPosts(first: 0)`, and `listPosts(last: 0, before: "<valid cursor>")`. A relationship field's `comments(limit: 0)` returns an empty list normally.

## Observed

`"Something went wrong. Unique error id: ..."` with
```
** (Ash.Error.Unknown)
* ** (Spark.Options.ValidationError) invalid value for :page option: invalid value for :limit option: expected positive integer, got: 0
```
in the log.

## Expected

A rendered error, or an empty page for 0 (the Relay connection spec treats `first: 0` as an empty connection).

## Failure point

`validate_keyset_opts/3`, [lib/graphql/resolver.ex#L1345-L1349](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L1345-L1349).

## Notes

Two defects stack here: `first` / `last` are mapped onto the page `limit` without validation, and Ash surfaces the resulting `Spark.Options.ValidationError` as `Ash.Error.Unknown` (reported separately as `ash/invalid-page-options-unrendered`). The ash_graphql half is the one this report is about; the negative page size report shares it.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_graphqlzero-page-size-unrendered
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/zero_page_size_test.exs
* Run: `mix setup && mix test test/ash_graphql/zero_page_size_test.exs` in https://github.com/grempe/ash-fuzz-repros
