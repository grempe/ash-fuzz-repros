# A returned error table is converted only at its top level

Versions: ash_lua 0.2.2, lua 1.0.2, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `2fb5f49` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`AshLua.Eval.run/2` on `local r, err = blog.post.read({ filter = { title = { nope = "x" } } }) return r, err` (returning `(result, err)` is the documented calling convention).

## Observed

The result's `error` is
```elixir
%{"class" => "invalid", "errors" => [{1, [{"code", "unknown_error"}, {"fields", []}, {"message", "..."}, {"short_message", "unknown_error"}, {"vars", [{"uuid", "..."}]}]}]}
```
Nested tables stay as lists of `{key, value}` tuples, so `Jason.encode/1` of the result returns `{:error, %Protocol.UndefinedError{protocol: Jason.Encoder, value: {1, [...]}}}`. By contrast a returned result table is converted at every depth, so only the error slot is affected.

## Expected

`"errors"` is a list of maps and the result is JSON-encodable.

## Failure point

`normalize_error/1` in `split_lua_return/1`, [lib/ash_lua/eval.ex#L231-L239](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/eval.ex#L231-L239).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_luareturned-error-table-converted-only-at-top-level
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/nested_error_table_test.exs
* Run: `mix setup && mix test test/ash_lua/nested_error_table_test.exs` in https://github.com/grempe/ash-fuzz-repros
