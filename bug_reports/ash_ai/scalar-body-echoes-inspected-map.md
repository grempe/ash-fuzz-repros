# A malformed request body is echoed back as an inspected Elixir term

Versions: ash_ai 1.0.3, ash 3.33.3, plug 1.20.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `158d5e9` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

The request body `5` (also `"hi"`, `true`, `null`, or any JSON object without a `method` key), on either protocol path.

## Observed

```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid Request Got: %{\"_json\" => 5}"}}
```
(HTTP 200 on the initialize-based path, 400 on the 2026-07-28 path.) The `_json` wrapper is `Plug.Parsers`' representation of a non-object body, so the message describes something the client did not send. An object without `method` is echoed with up to 50 of its own keys and values.

## Expected

A fixed message with no inspected terms.

## Failure point

`inspect(other)` in the catch-all clauses at [lib/ash_ai/mcp/server.ex#L200](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L200) and [#L836](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L836).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_aiscalar-body-echoes-inspected-map
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_ai/scalar_body_echoes_inspected_map_test.exs
* Run: `mix setup && mix test test/ash_ai/scalar_body_echoes_inspected_map_test.exs` in https://github.com/grempe/ash-fuzz-repros
