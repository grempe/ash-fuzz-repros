# Bug reports for ash-project/ash_graphql

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash_graphql 1.11.0, absinthe 1.12.0, absinthe_plug 1.5.10, ash 3.33.3, ash_postgres 2.13.1, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| A null, empty or multi-element boolean filter crashes the resolver | [README](https://github.com/grempe/ash-fuzz-repros#ash_graphqlnull-boolean-filter-crash), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/null_boolean_filter_test.exs), [draft](ash_graphql/null-boolean-filter-crash.md) |
| A negative page size makes complexity analysis raise | [README](https://github.com/grempe/ash-fuzz-repros#ash_graphqlnegative-page-size-complexity), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/negative_page_size_complexity_test.exs), [draft](ash_graphql/negative-page-size-complexity.md) |
| InvalidFilterValue has no GraphQL rendering | [README](https://github.com/grempe/ash-fuzz-repros#ash_graphqlunrendered-invalid-filter-value), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/unrendered_invalid_filter_value_test.exs), [draft](ash_graphql/unrendered-invalid-filter-value.md) |
| first: 0 and last: 0 are an unrendered error | [README](https://github.com/grempe/ash-fuzz-repros#ash_graphqlzero-page-size-unrendered), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_graphql/zero_page_size_test.exs), [draft](ash_graphql/zero-page-size-unrendered.md) |
