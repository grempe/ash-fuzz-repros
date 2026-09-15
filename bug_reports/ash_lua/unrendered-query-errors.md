# InvalidFilterValue, NoSuchFilterPredicate and NoSuchField have no Lua rendering

Versions: ash_lua 0.2.2, lua 1.0.2, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `2fb5f49` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`blog.post.read({ filter = { id = "not-a-uuid" } })`, `blog.post.read({ filter = { title = { nope = "x" } } })`, `blog.post.read({ filter = { nope = "x" } })`.

## Observed

`code = "unknown_error"` with a uuid, and `AshLua.Error not implemented for error: ** (Ash.Error.Query.NoSuchField) No such field nope for resource Repro.Post` (and the other two) in the log. A `fields` mistake, by contrast, renders as `unknown_field` with the field name.

## Expected

Structured errors naming the field or predicate.

## Failure point

No `AshLua.Error` implementation for the three errors in [lib/ash_lua/error.ex](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/error.ex); `render_error/1` falls back to `log_unknown_error/1`, [lib/ash_lua/encoder.ex#L493-L501](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/encoder.ex#L493-L501) and L532-L554.

## Notes

On ash_postgres, `Exception.message/1` of `InvalidFilterValue` contains the full inspected Ecto query (its `:context` holds the query struct), and the other two interpolate `inspect(resource)`, so a rendering that reuses those messages would expose that to the script.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_luaunrendered-query-errors
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/unrendered_query_errors_test.exs
* Run: `mix setup && mix test test/ash_lua/unrendered_query_errors_test.exs` in https://github.com/grempe/ash-fuzz-repros
