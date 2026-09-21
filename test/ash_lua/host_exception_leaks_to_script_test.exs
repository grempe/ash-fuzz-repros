defmodule Repro.AshLua.HostExceptionLeaksToScriptTest do
  @moduledoc """
  ash-project/ash_lua: an exception raised while ash_lua builds the query,
  before the action is dispatched, reaches the script as a `lua_error` whose
  message is the host exception text ("Lua runtime error: no function clause
  matching in Ash.Filter.parse_and_join/3"). The envelope also lacks the
  documented top-level `class` key. Expected: a structured invalid input error
  without exception text.

  Both triggers stopped raising once Ash fixed the underlying crashes (the sort
  case in ash 3.33.5, the filter case in ash 3.33.6), so the tests pass on the
  pinned releases. ash_lua's own fix (commit 895745e) is on its main branch and
  not in a release yet.
  """
  use Repro.Case, async: false

  @bug "ash_lua/host-exception-leaks-to-script"

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: a well-formed combinator and sort run normally" do
    assert %{error: nil, result: [_]} =
             lua(
               ~S|local r, err = blog.post.read({ filter = { ["or"] = { { title = "one" } } }, sort = "title" }) return r, err|
             )
  end

  @tag bug: @bug,
       fixed_in: "ash 3.33.6",
       signature: [
         "Lua runtime error: no function clause matching in Ash.Filter.parse_and_join/3"
       ]
  test "filter = { or = {} } returns a structured error" do
    assert %{"class" => "invalid", "errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { ["or"] = {} } }) return r, err|
             )

    assert code != "lua_error"
  end

  @tag bug: @bug,
       fixed_in: "ash 3.33.5",
       signature: ["Lua runtime error: no function clause matching in Ash.Sort.parse_input/3"]
  test "sort = 5 returns a structured error" do
    assert %{"errors" => [%{"code" => code, "message" => message}]} =
             lua_error(~S|local r, err = blog.post.read({ sort = 5 }) return r, err|)

    assert code != "lua_error", "got a lua_error: #{message}"
  end
end
