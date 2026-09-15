# A null, empty or multi-element boolean filter crashes the resolver

Versions: ash_graphql 1.11.0, absinthe 1.12.0, absinthe_plug 1.5.10, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `fd31401` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`listPosts(filter: {and: null})`, `{or: null}`, `{not: null}`, `{not: []}`, and `{not: [{title: {eq: "x"}}, {score: {eq: 9}}]}` (a `not` list with more than one element). The generated schema types `and`, `or` and `not` as `[PostFilterInput!]`, a nullable list, so all of these pass validation.

## Observed

`"Something went wrong. Unique error id: ..."` with
```
** (FunctionClauseError) no function clause matching in AshGraphql.Graphql.FilterHandlers.process_boolean_filter/5
    (ash_graphql 1.11.0) lib/graphql/filter_handlers.ex:172
```
in the log. `{and: []}` and `{or: []}` are handled.

## Expected

The combinator is applied (or ignored when empty), or a rendered invalid filter error.

## Failure point

`AshGraphql.Graphql.FilterHandlers.process_boolean_filter/5`, [lib/graphql/filter_handlers.ex#L172-L181](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/filter_handlers.ex#L172-L181).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_graphqlnull-boolean-filter-crash
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/null_boolean_filter_test.exs
* Run: `mix setup && mix test test/ash_graphql/null_boolean_filter_test.exs` in https://github.com/grempe/ash-fuzz-repros
