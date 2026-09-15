# filter_input crashes on `and` / `or` with a value that is not a non-empty list or map

Versions: ash 3.33.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `a7a5105` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`Ash.Query.filter_input(Post, %{"and" => "x"})`; also `%{"or" => ""}`, `%{"or" => %{}}`, `%{"or" => []}`, `%{"or" => nil}` and `%{"and" => 5}`. Through AshJsonApi: `GET /posts?filter[and]=x`.

## Observed

```
** (FunctionClauseError) no function clause matching in Ash.Filter.parse_and_join/3
    (ash 3.33.3) lib/ash/filter/filter.ex:4942
```
The JSON:API request raises the same exception through the router (a 500). By contrast `Ash.Query.filter_input(Post, %{"not" => "x"})` puts an `Ash.Error.Query.InvalidFilterValue` on the query.

## Expected

`{:error, %Ash.Error.Invalid{}}` with an invalid filter error; a 400 on JSON:API.

## Failure point

`Ash.Filter.parse_and_join/3`, [lib/ash/filter/filter.ex#L4942-L4960](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/filter/filter.ex#L4942-L4960), called from `add_expression_part/4` at L3050 and L3058.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ashfilter-combinator-shape
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/filter_combinator_shape_test.exs
* Run: `mix setup && mix test test/ash/filter_combinator_shape_test.exs` in https://github.com/grempe/ash-fuzz-repros
