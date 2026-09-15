# Bug reports for elixir-ecto/ecto

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ecto 3.14.2, ecto_sql 3.14.0, postgrex 0.22.4, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| Inspecting a query that holds a three-tuple such as {Foo, :cache, [...]} raises, so Ecto.Query.CastError cannot be raised | [README](https://github.com/grempe/ash-fuzz-repros#ectoinspect-query-crashes-on-spark-regex-type-param), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ecto/inspect_query_with_spark_regex_type_param_test.exs), [draft](ecto/inspect-query-crashes-on-spark-regex-type-param.md) |
