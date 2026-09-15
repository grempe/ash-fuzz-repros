# Bug reports for ash-project/ash_lua

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash_lua 0.2.2, lua 1.0.2, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| A returned error table is converted only at its top level | [README](https://github.com/grempe/ash-fuzz-repros#ash_luareturned-error-table-converted-only-at-top-level), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/nested_error_table_test.exs), [draft](ash_lua/returned-error-table-converted-only-at-top-level.md) |
| A host exception raised before dispatch reaches the script verbatim | [README](https://github.com/grempe/ash-fuzz-repros#ash_luahost-exception-leaks-to-script), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/host_exception_leaks_to_script_test.exs), [draft](ash_lua/host-exception-leaks-to-script.md) |
| Action input is merged under the query controls | [README](https://github.com/grempe/ash-fuzz-repros#ash_luaaction-input-merged-under-query-controls), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/action_input_merged_under_controls_test.exs), [draft](ash_lua/action-input-merged-under-query-controls.md) |
| InvalidFilterValue, NoSuchFilterPredicate and NoSuchField have no Lua rendering | [README](https://github.com/grempe/ash-fuzz-repros#ash_luaunrendered-query-errors), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_lua/unrendered_query_errors_test.exs), [draft](ash_lua/unrendered-query-errors.md) |
