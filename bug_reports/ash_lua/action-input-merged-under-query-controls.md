# Action input is merged under the query controls

Versions: ash_lua 0.2.2, lua 1.0.2, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `2fb5f49` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

A read action with an argument named `limit` (`read :search do argument :limit, :integer end`) and three posts: `blog.post.search({ input = { limit = 1 } })`. Also `blog.post.search({ input = { limit = 2^63 } })` (a Lua float) and the control key `blog.post.read({ limit = "x" })`.

## Observed

The first call returns one post with no error: the action argument was applied as the query limit, and the argument never reaches the action. The generated documentation for the action (`AshLua.Eval.docs/2`) lists both `input.limit` and the control key `limit`. The second call returns `unknown_error` with `AshLua.Error not implemented for error: ** (Ash.Error.Query.InvalidLimit) 9.223372036854776e18 is not a valid limit` in the log; `limit = "x"` is the same unrendered `InvalidLimit`. Those two are a separate gap of the same kind as the ash_lua unrendered-query-errors report.

## Expected

`input.limit` reaches the action as an argument, or the name collision is rejected at compile time as a renamed argument onto a reserved key already is. An invalid limit is a rendered error.

## Failure point

`input = Map.merge(action_input, controls)` at [lib/ash_lua/runtime.ex#L586](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L586); the pops of `page`, `filter`, `sort`, `limit`, `offset` at L754-L759 and L873-L877. `Ash.Error.Query.InvalidLimit` has no `AshLua.Error` implementation.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_luaaction-input-merged-under-query-controls
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/action_input_merged_under_controls_test.exs
* Run: `mix setup && mix test test/ash_lua/action_input_merged_under_controls_test.exs` in https://github.com/grempe/ash-fuzz-repros
