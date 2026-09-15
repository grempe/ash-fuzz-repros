# A negative page size makes complexity analysis raise

Versions: ash_graphql 1.11.0, absinthe 1.12.0, absinthe_plug 1.5.10, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `fd31401` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

With `analyze_complexity: true` on `Absinthe.Plug` (the configuration in ash_graphql's own documentation): `listPosts(first: -1)`, `listPosts(last: -1)`, or a relationship field `comments(limit: -1)`.

## Observed

The request raises before any resolver runs (a 500 with no GraphQL error body):
```
** (Absinthe.AnalysisError) Invalid value returned from complexity analyzer.
Analyzing field: listPosts ... Got value: -2
The complexity value must be a non negative integer.
```
Setting `max_complexity` does not change this; the raise happens in Absinthe's analysis phase before the limit is read. With `analyze_complexity: false`, `listPosts(first: -1)` is the same unrendered `Spark.Options.ValidationError` as `first: 0` (see zero-page-size-unrendered), while `comments(limit: -1)` returns an empty list.

## Expected

A GraphQL error for the invalid page size, and a complexity value that is never negative.

## Failure point

`AshGraphql.Graphql.Resolver.query_complexity/3`, [lib/graphql/resolver.ex#L3498-L3538](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L3498-L3538); Absinthe raises for a negative return at [lib/absinthe/phase/document/complexity/analysis.ex#L88-L95](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/phase/document/complexity/analysis.ex#L88-L95).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_graphqlnegative-page-size-complexity
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/negative_page_size_complexity_test.exs
* Run: `mix setup && mix test test/ash_graphql/negative_page_size_complexity_test.exs` in https://github.com/grempe/ash-fuzz-repros
