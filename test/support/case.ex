defmodule Repro.Case do
  @moduledoc """
  Shared test setup: an Ecto SQL sandbox checkout in shared mode (Ash may run
  parts of a read in tasks), seed helpers, and one small driver per surface.
  """
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Plug.Conn
      import Plug.Test
      import Repro.Case
      import ExUnit.CaptureLog
      require Ash.Query
      alias Repro.{Comment, Post, Router}
    end
  end

  setup do
    :ok = Sandbox.checkout(Repro.Repo)
    Sandbox.mode(Repro.Repo, {:shared, self()})
    :ok
  end

  def create_post(attrs \\ %{}) do
    Ash.create!(Repro.Post, Map.merge(%{title: "hello", score: 1}, attrs), authorize?: false)
  end

  def create_comment(post, attrs \\ %{}) do
    Ash.Seed.seed!(Repro.Comment, Map.merge(%{body: "a comment", post_id: post.id}, attrs))
  end

  @doc "Sends a JSON:API request through the router. Returns `{status, decoded body}`."
  def json_api(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, "/api" <> path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("accept", "application/vnd.api+json")
      |> Plug.Conn.put_req_header("content-type", "application/vnd.api+json")
      |> Repro.Router.call(Repro.Router.init([]))

    {conn.status, decode(conn.resp_body)}
  end

  @doc "Runs a GraphQL document through Absinthe.Plug. Returns `{status, decoded body}`."
  def graphql(query, variables \\ %{}) do
    conn =
      Plug.Test.conn(:post, "/gql", Jason.encode!(%{query: query, variables: variables}))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Repro.Router.call(Repro.Router.init([]))

    {conn.status, decode(conn.resp_body)}
  end

  @doc "Evaluates a Lua script against the eval surface. Returns the run result map as is."
  def lua(script) do
    {:ok, result} = AshLua.Eval.run(script, eval_resource: Repro.LuaSurface)
    result
  end

  @doc """
  Evaluates a Lua script and returns its `error` with every nested Lua table
  converted to maps and lists. `AshLua.Eval.run/2` only converts the top level
  of a returned error table (an ash_lua bug with its own test), so the other
  Lua tests use this to assert on error codes independently of that bug.
  """
  def lua_error(script) do
    script |> lua() |> Map.fetch!(:error) |> from_lua_table()
  end

  defp from_lua_table(list) when is_list(list) do
    cond do
      list != [] and Enum.all?(list, &match?({key, _} when is_integer(key), &1)) ->
        list |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&from_lua_table(elem(&1, 1)))

      list != [] and Enum.all?(list, &match?({_, _}, &1)) ->
        Map.new(list, fn {key, value} -> {key, from_lua_table(value)} end)

      true ->
        Enum.map(list, &from_lua_table/1)
    end
  end

  defp from_lua_table(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {key, from_lua_table(value)} end)
  end

  defp from_lua_table(other), do: other

  @mcp_opts AshAi.Mcp.Router.init(tools: [:read_posts], otp_app: :repro)

  @doc """
  Posts a JSON-RPC body to the ash_ai MCP router, mounted with one tool. `body`
  is encoded as given, so it can be a map, a list or a bare scalar. Returns
  `{status, decoded body}`.
  """
  def mcp(body, headers \\ []) do
    conn =
      Plug.Test.conn(:post, "/", Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("accept", "application/json")

    conn =
      Enum.reduce(headers, conn, fn {name, value}, conn ->
        Plug.Conn.put_req_header(conn, name, value)
      end)

    conn = AshAi.Mcp.Router.call(conn, @mcp_opts)
    {conn.status, decode(conn.resp_body)}
  end

  @doc """
  Runs `fun` with `config :ash, :disable_async?` set, restoring the previous
  value afterwards. Some bugs only show when Ash runs its count query inline.
  """
  def with_disabled_async(fun) do
    previous = Application.get_env(:ash, :disable_async?)
    Application.put_env(:ash, :disable_async?, true)

    try do
      fun.()
    after
      case previous do
        nil -> Application.delete_env(:ash, :disable_async?)
        value -> Application.put_env(:ash, :disable_async?, value)
      end
    end
  end

  defp decode(""), do: nil

  defp decode(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end
end
