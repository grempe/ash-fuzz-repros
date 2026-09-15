defmodule Repro.AshAi.MalformedJsonRpcEnvelopeTest do
  @moduledoc """
  ash-project/ash_ai: `AshAi.Mcp.Server` reads the JSON-RPC envelope with
  `Access` and pattern matches that assume objects. A batch array has no
  matching clause in `parse_json_rpc/1` on the initialize-based path, and
  `params`, `params.arguments` or `params.capabilities` given as a string or a
  list raise inside `Access.get/3` on both protocol paths.

  Paths: the initialize-based `2025-06-18` / `2025-03-26` path (no
  `MCP-Protocol-Version` header, no `_meta`) and the per-request `2026-07-28`
  path (header plus `_meta` in `params`).
  """
  use Repro.Case, async: false

  @bug "ash_ai/malformed-json-rpc-envelope"
  @batch ["FunctionClauseError", "AshAi.Mcp.Server.parse_json_rpc/1"]
  @string_access ["FunctionClauseError", "Access.get/3"]
  @list_access ["ArgumentError", "the Access module supports only keyword lists"]

  @new_headers [{"mcp-protocol-version", "2026-07-28"}]
  @call_headers @new_headers ++ [{"mcp-method", "tools/call"}, {"mcp-name", "read_posts"}]
  @meta %{
    "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
    "io.modelcontextprotocol/clientCapabilities" => %{},
    "io.modelcontextprotocol/clientInfo" => %{"name" => "repro", "version" => "1"}
  }

  defp request(method, params),
    do: %{"jsonrpc" => "2.0", "id" => 1, "method" => method, "params" => params}

  test "control: tools/list and tools/call work on both paths" do
    assert {200, %{"result" => %{"tools" => [%{"name" => "read_posts"}]}}} =
             mcp(request("tools/list", %{}))

    assert {200, %{"result" => %{"content" => [_]}}} =
             mcp(request("tools/call", %{"name" => "read_posts", "arguments" => %{}}))

    assert {200, %{"result" => %{"tools" => [%{"name" => "read_posts"}]}}} =
             mcp(
               request("tools/list", %{"_meta" => @meta}),
               @new_headers ++ [{"mcp-method", "tools/list"}]
             )

    assert {200, %{"result" => %{"content" => [_]}}} =
             mcp(
               request("tools/call", %{
                 "name" => "read_posts",
                 "arguments" => %{},
                 "_meta" => @meta
               }),
               @call_headers
             )
  end

  test "control: the 2026-07-28 path rejects a batch and a non-object _meta cleanly" do
    assert {400, %{"error" => %{"code" => -32600}}} = mcp([], @new_headers)

    assert {400, %{"error" => %{"code" => -32600}}} =
             mcp([request("tools/list", %{"_meta" => @meta})], @new_headers)

    assert {400, %{"error" => %{"code" => -32602}}} =
             mcp(request("tools/list", %{"_meta" => "x"}), @new_headers)

    assert {400, %{"error" => %{"code" => -32602}}} =
             mcp(request("tools/list", %{"_meta" => []}), @new_headers)
  end

  test "control: a method that ignores params answers 200 with scalar params on the initialize-based path" do
    assert {200, %{"result" => %{"tools" => [_]}}} = mcp(request("tools/list", "x"))
  end

  @tag bug: @bug, signature: @batch
  test "initialize-based path: an empty batch is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "error" => %{"code" => -32600}}} = mcp([])
  end

  @tag bug: @bug, signature: @batch
  test "initialize-based path: a one-element batch is answered or rejected with -32600" do
    assert {_, response} = mcp([request("tools/list", %{})])

    assert match?([%{"jsonrpc" => "2.0", "id" => 1, "result" => _}], response) or
             match?(%{"jsonrpc" => "2.0", "error" => %{"code" => -32600}}, response)
  end

  @tag bug: @bug, signature: @string_access
  test "initialize-based path: params as a string is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => code}}} =
             mcp(request("tools/call", "x"))

    assert code in [-32600, -32602]
  end

  @tag bug: @bug, signature: @list_access
  test "initialize-based path: params as a list is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => code}}} =
             mcp(request("tools/call", []))

    assert code in [-32600, -32602]
  end

  @tag bug: @bug, signature: @string_access
  test "initialize-based path: params.arguments as a string is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32602}}} =
             mcp(request("tools/call", %{"name" => "read_posts", "arguments" => "x"}))
  end

  @tag bug: @bug, signature: @list_access
  test "initialize-based path: params.arguments as a list is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32602}}} =
             mcp(request("tools/call", %{"name" => "read_posts", "arguments" => []}))
  end

  @tag bug: @bug, signature: @string_access
  test "initialize-based path: initialize with params.capabilities as a string is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32602}}} =
             mcp(
               request("initialize", %{
                 "protocolVersion" => "2025-06-18",
                 "capabilities" => "x",
                 "clientInfo" => %{}
               })
             )
  end

  @tag bug: @bug, signature: @string_access
  test "2026-07-28 path: params as a string is a JSON-RPC error" do
    assert {400, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => code}}} =
             mcp(request("tools/call", "x"), @new_headers)

    assert code in [-32600, -32602]
  end

  @tag bug: @bug, signature: @list_access
  test "2026-07-28 path: params as a list is a JSON-RPC error" do
    assert {400, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => code}}} =
             mcp(request("tools/call", []), @new_headers)

    assert code in [-32600, -32602]
  end

  @tag bug: @bug, signature: @string_access
  test "2026-07-28 path: params.arguments as a string is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32602}}} =
             mcp(
               request("tools/call", %{
                 "name" => "read_posts",
                 "arguments" => "x",
                 "_meta" => @meta
               }),
               @call_headers
             )
  end

  @tag bug: @bug, signature: @list_access
  test "2026-07-28 path: params.arguments as a list is a JSON-RPC error" do
    assert {_, %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32602}}} =
             mcp(
               request("tools/call", %{
                 "name" => "read_posts",
                 "arguments" => [],
                 "_meta" => @meta
               }),
               @call_headers
             )
  end
end
