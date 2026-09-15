# sort_input crashes on a value that is neither a string nor a list

Versions: ash 3.33.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `a7a5105` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`Ash.Query.sort_input(Post, 5)`; also `%{}`, `%{"title" => "asc"}` and `[%{"field" => "title"}]`.

## Observed

```
** (FunctionClauseError) no function clause matching in Ash.Sort.parse_input/3
```
For the list of maps: `no function clause matching in Ash.Resource.Info.attribute/2`. By contrast `Ash.Query.filter_input(Post, "title")` puts an `InvalidFilterValue` on the query.

## Expected

An invalid-class error on the query. A map is not a documented sort format; the request is an invalid-sort error, not map support.

## Failure point

`Ash.Sort.parse_input/3`, [lib/ash/sort/sort.ex#L94-L126](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/sort/sort.ex#L94-L126).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ashsort-input-shape
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/sort_input_shape_test.exs
* Run: `mix setup && mix test test/ash/sort_input_shape_test.exs` in https://github.com/grempe/ash-fuzz-repros
