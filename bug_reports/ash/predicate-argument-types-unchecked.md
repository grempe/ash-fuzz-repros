# Input filters do not check a predicate's argument types against the referenced attribute

Versions: ash 3.33.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `a7a5105` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

On a `:string` attribute: `Post |> Ash.Query.filter_input(%{"title" => %{"range_overlaps" => "x"}}) |> Ash.read()`, also `range_adjacent` and `range_contains`. On an `:integer` attribute: `filter_input(Post, %{"score" => %{"contains" => "x"}})`. Through AshJsonApi: `GET /posts?filter[title][range_overlaps]=x`. Through AshGraphql: `listPosts(filter: {title: {rangeOverlaps: "x"}})`.

## Observed

The filter parses and reaches Postgres:
```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (Postgrex.Error) ERROR 42883 (undefined_function) operator does not exist: text && unknown ..."}]}}
```
(`-|-` for adjacent, `@>` for contains, `bigint ~~ unknown` for `contains` on the integer.) JSON:API answers 500; GraphQL answers "Something went wrong".

## Expected

An invalid filter error when the filter is parsed.

## Failure point

`Ash.Filter.get_predicate_function/3`, [lib/ash/filter/filter.ex#L5147-L5157](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/filter/filter.ex#L5147-L5157), and `Ash.Query.Function.try_cast_arguments/2`, [lib/ash/query/function/function.ex#L146-L190](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/function.ex#L146-L190); the range predicates' `args/0` in [range_overlaps.ex#L19](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_overlaps.ex#L19), [range_adjacent.ex#L18](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_adjacent.ex#L18), [range_contains.ex#L18](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_contains.ex#L18).

## Notes

The three range predicates declare their argument types as `[:any, :same]` (`[:any, :any]` for `range_contains`). AshJsonApi's OpenAPI filter schema and AshGraphql's filter input types build their per-field predicate lists from those declarations, so both list the range predicates on every field, including text; the GraphQL introspection test in the repository shows that and is tagged with this report.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ashpredicate-argument-types-unchecked
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/predicate_argument_types_unchecked_test.exs
* Run: `mix setup && mix test test/ash/predicate_argument_types_unchecked_test.exs` in https://github.com/grempe/ash-fuzz-repros
