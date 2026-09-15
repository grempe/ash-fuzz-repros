# Bug reports for ash-project/ash_json_api

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash_json_api 1.7.1, ash 3.33.3, ash_postgres 2.13.1, plug 1.20.3, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| include[], fields[type][], page[] and page[limit][] crash the request parser | [README](https://github.com/grempe/ash-fuzz-repros#ash_json_apilist-valued-query-params-crash), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_json_api/list_valued_query_params_test.exs), [draft](ash_json_api/list-valued-query-params-crash.md) |
