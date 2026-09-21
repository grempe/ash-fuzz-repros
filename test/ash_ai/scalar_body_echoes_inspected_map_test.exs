defmodule Repro.AshAi.ScalarBodyEchoesInspectedMapTest do
  @moduledoc """
  ash-project/ash_ai: a bare JSON scalar body such as `5` is wrapped by
  `Plug.Parsers` as `%{"_json" => 5}`, and the server answers "Invalid Request
  Got: %{\\"_json\\" => 5}", an inspected Elixir term in a client-facing message.
  The same happens on both protocol paths.

  Fixed in ash_ai 1.1.0 (ash-project/ash_ai#234). The bug tests pass on the pinned release and are
  kept as regression checks; `signature:` records how they used to fail.
  """
  use Repro.Case, async: false

  @moduletag fixed_in: "ash_ai 1.1.0"

  @bug "ash_ai/scalar-body-echoes-inspected-map"
  @signature ["Invalid Request Got: %{", "_json"]

  test "control: an object without a method is rejected with a JSON-RPC error" do
    assert {200, %{"jsonrpc" => "2.0", "result" => %{}}} =
             mcp(%{"jsonrpc" => "2.0", "id" => 1, "method" => "ping"})
  end

  @tag bug: @bug, signature: @signature
  test "initialize-based path: the body 5 gets a message without inspected terms" do
    assert {_, %{"jsonrpc" => "2.0", "error" => %{"code" => -32_600, "message" => message}}} =
             mcp(5)

    refute message =~ "%{"
  end

  @tag bug: @bug, signature: @signature
  test "2026-07-28 path: the body 5 gets a message without inspected terms" do
    assert {400, %{"jsonrpc" => "2.0", "error" => %{"code" => -32_600, "message" => message}}} =
             mcp(5, [{"mcp-protocol-version", "2026-07-28"}])

    refute message =~ "%{"
  end
end
