# Bug reports for ash-project/ash_ai

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash_ai 1.0.3, ash 3.33.3, plug 1.20.3, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| Malformed JSON-RPC envelopes crash the MCP server | [README](https://github.com/grempe/ash-fuzz-repros#ash_aimalformed-json-rpc-envelope), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_ai/malformed_json_rpc_envelope_test.exs), [draft](ash_ai/malformed-json-rpc-envelope.md) |
| A malformed request body is echoed back as an inspected Elixir term | [README](https://github.com/grempe/ash-fuzz-repros#ash_aiscalar-body-echoes-inspected-map), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_ai/scalar_body_echoes_inspected_map_test.exs), [draft](ash_ai/scalar-body-echoes-inspected-map.md) |
