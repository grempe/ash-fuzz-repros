# Bug reports for absinthe-graphql/absinthe

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (absinthe 1.12.0, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| A lone surrogate escape, or a surrogate pair escape, leaks Erlang's ArgumentError text | [README](https://github.com/grempe/ash-fuzz-repros#absinthelone-surrogate-escape-leaks-argument-error), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/absinthe/lone_surrogate_escape_test.exs), [draft](absinthe/lone-surrogate-escape-leaks-argument-error.md) |
