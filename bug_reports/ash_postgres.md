# Bug reports for ash-project/ash_postgres

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash_postgres 2.13.1, ash_sql 0.7.5, ash 3.33.3, ecto 3.14.2, postgrex 0.22.4, PostgreSQL 18.6, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| Ecto.Query.CastError is converted only where a rescue exists, and Ecto.SubQueryError is never unwrapped | [README](https://github.com/grempe/ash-fuzz-repros#ash_postgresuncastable-filter-value-conversion), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/uncastable_filter_value_conversion_test.exs), [draft](ash_postgres/uncastable-filter-value-conversion.md) |
| A NUL byte in text is an unconverted Postgrex.Error | [README](https://github.com/grempe/ash-fuzz-repros#ash_postgresnul-byte-in-text), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/nul_byte_in_text_test.exs), [draft](ash_postgres/nul-byte-in-text.md) |
| An integer outside the bigint range is an unconverted DBConnection.EncodeError | [README](https://github.com/grempe/ash-fuzz-repros#ash_postgresinteger-past-64-bits-unconverted), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/integer_past_64_bits_test.exs), [draft](ash_postgres/integer-past-64-bits-unconverted.md) |
