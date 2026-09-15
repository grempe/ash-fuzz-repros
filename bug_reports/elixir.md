# Bug reports for elixir-lang/elixir

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (Elixir 1.18.4, 1.19.5, 1.20.1 and 1.20.2 on OTP 27 to 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| Macro.to_string/1 crashes instead of inspecting a three-tuple whose second element is not a keyword list | [README](https://github.com/grempe/ash-fuzz-repros#elixirmacro-to-string-mfa-tuple), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/elixir/macro_to_string_mfa_tuple_test.exs), [draft](elixir/macro-to-string-mfa-tuple.md) |
