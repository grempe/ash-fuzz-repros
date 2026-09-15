defmodule Repro.Router do
  @moduledoc """
  A plain Plug router. Tests drive it with `Plug.Test`; no server runs.

    * `/api` is the JSON:API router.
    * `/gql` is Absinthe.Plug with complexity analysis enabled (one bug needs it).

  The ash_ai MCP router is not forwarded from here: `Plug.Router.forward/2` adds a
  `glob` path parameter to `conn.params`, which the MCP server would echo. Tests
  call `AshAi.Mcp.Router` directly instead (see `Repro.Case.mcp/2`).
  """
  use Plug.Router

  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :match
  plug :dispatch

  forward "/api", to: Repro.JsonApiRouter

  forward "/gql",
    to: Absinthe.Plug,
    init_opts: [schema: Repro.Schema, analyze_complexity: true, json_codec: Jason]

  match _ do
    send_resp(conn, 404, "not found")
  end
end
