# InvalidFilterValue has no GraphQL rendering

Versions: ash_graphql 1.11.0, absinthe 1.12.0, absinthe_plug 1.5.10, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `fd31401` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`getPost(id: "not-a-uuid")` or `listPosts(filter: {id: {eq: "not-a-uuid"}})`.

## Observed

```
{"errors":[{"message":"Something went wrong. Unique error id: ..."}]}
```
with `AshGraphql.Error not implemented for error: ** (Ash.Error.Query.InvalidFilterValue) ...` in the log. The query path returns only `message`, with no `code`, `fields` or `vars`.

## Expected

An error with `code: "invalid_filter_value"`.

## Failure point

No `AshGraphql.Error` implementation for `Ash.Error.Query.InvalidFilterValue` in [lib/error.ex](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/error.ex); rendered by `AshGraphql.Graphql.Resolver.to_resolution/3`, [lib/graphql/resolver.ex#L3616-L3660](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L3616-L3660) (queries), and `AshGraphql.Errors.to_errors/6`, [lib/graphql/errors.ex#L28-L78](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/errors.ex#L28-L78) (mutations).

## Notes

On ash_postgres, `Exception.message/1` of this error contains the full inspected Ecto query, so a rendering that reuses it would expose that.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_graphqlunrendered-invalid-filter-value
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/unrendered_invalid_filter_value_test.exs
* Run: `mix setup && mix test test/ash_graphql/unrendered_invalid_filter_value_test.exs` in https://github.com/grempe/ash-fuzz-repros
