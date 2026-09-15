# Malformed JSON-RPC envelopes crash the MCP server

Versions: ash_ai 1.0.3, ash 3.33.3, plug 1.20.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `158d5e9` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`AshAi.Mcp.Router` with `tools: [:read_posts]`, called with `Plug.Test` as ash_ai's own tests do (the router runs its own `Plug.Parsers`). "Initialize-based path": no `MCP-Protocol-Version` header and no `_meta` (a header naming an earlier revision selects it too). "2026-07-28 path": header `MCP-Protocol-Version: 2026-07-28` and `_meta` in `params`.

| Body | initialize-based path | 2026-07-28 path |
|---|---|---|
| a batch array, `[]` or `[{"jsonrpc":"2.0","id":1,"method":"tools/list"}]` | raises `FunctionClauseError` in `AshAi.Mcp.Server.parse_json_rpc/1` | clean `-32600` |
| `"params": "x"` on `tools/call` or `initialize` (`tools/list` ignores `params` and answers 200) | raises `FunctionClauseError` in `Access.get/3` | raises, for every method with an id |
| `"params": []` on the same methods | raises `ArgumentError` (the Access module supports only keyword lists) | raises, for every method with an id |
| `tools/call` with `"arguments": "x"` or `[]` | the same two raises | the same two raises |
| `initialize` with `"capabilities": "x"` or `[]` | raises `FunctionClauseError` in `Access.get/3` | not applicable |

`params._meta` as a string or list is ignored on the initialize-based path and rejected with `-32602` on the 2026-07-28 path; `params.clientInfo` is not read on either path. Neither crashes.

## Observed

Each raise propagates through the router (a 500 with no JSON-RPC body), for example:
```
** (FunctionClauseError) no function clause matching in AshAi.Mcp.Server.parse_json_rpc/1
```
A non-object `input` inside `arguments` is already rejected with a helpful message; the enclosing `arguments` is not.

## Expected

A JSON-RPC error (`-32600` or `-32602`) with the request's id where it has one.

## Failure point

[lib/ash_ai/mcp/server.ex](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex): `unwrap_json_params/1` L111 with `parse_json_rpc/1` L1336-L1345 (batches); `execute_tool_call/3` L974 (`params["name"]`); `validate_request_meta/1` L206 (2026-07-28 path); `ui_capable?/1` L880 via `maybe_add_ui_capability/3` L858-L859 (`capabilities`); and `AshAi.Tool.Execution.run/4`, [lib/ash_ai/tool/execution.ex#L56](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/tool/execution.ex#L56) (`arguments["input"]`).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_aimalformed-json-rpc-envelope
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_ai/malformed_json_rpc_envelope_test.exs
* Run: `mix setup && mix test test/ash_ai/malformed_json_rpc_envelope_test.exs` in https://github.com/grempe/ash-fuzz-repros
