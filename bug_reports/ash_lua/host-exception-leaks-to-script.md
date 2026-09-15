# A host exception raised before dispatch reaches the script verbatim

Versions: ash_lua 0.2.2, lua 1.0.2, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29. Present on the default branch at `2fb5f49` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`blog.post.read({ filter = { ["or"] = {} } })` and `blog.post.read({ sort = 5 })`.

## Observed

The call does not return `(nil, err)`; the whole script aborts (its `print_output` is lost) and the run result's error is
```elixir
%{"errors" => [%{"code" => "lua_error", "message" => "Lua runtime error: no function clause matching in Ash.Filter.parse_and_join/3", "vars" => %{}, ...}]}
```
(`Ash.Sort.parse_input/3` for the sort). The envelope has no top-level `class`. The same happens for a raise from the data layer, for example `Ecto.Query.CastError` on `operation = "count"` with an uncastable id. The two Ash-side raises are reported to Ash; this report is about the exception text reaching the script as a `lua_error`.

## Expected

A structured invalid-input error returned as `(nil, err)`, without exception text.

## Failure point

The unguarded `Ash.Query.filter_input/2` and `Ash.Query.sort_input/2` calls at [lib/ash_lua/runtime.ex#L970-L974](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L970-L974); the rendering with `Exception.message/1` at [lib/ash_lua/eval.ex#L255-L258](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/eval.ex#L255-L258).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_luahost-exception-leaks-to-script
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/host_exception_leaks_to_script_test.exs
* Run: `mix setup && mix test test/ash_lua/host_exception_leaks_to_script_test.exs` in https://github.com/grempe/ash-fuzz-repros
