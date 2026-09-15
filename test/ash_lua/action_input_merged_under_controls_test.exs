defmodule Repro.AshLua.ActionInputMergedUnderControlsTest do
  @moduledoc """
  ash-project/ash_lua: the runtime merges a call's `input` map under the call's
  own keys before it takes `filter`, `sort`, `limit`, `offset` and `page` out.
  A read action argument named `limit` therefore becomes the query limit. A
  Lua float such as `2^63` then reaches `Ash.Query.limit/2` and produces an
  `Ash.Error.Query.InvalidLimit`, which has no Lua rendering. A control key
  `limit = "x"` is the same unrendered error.
  """
  use Repro.Case, async: false

  @bug "ash_lua/action-input-merged-under-query-controls"

  setup do
    for title <- ["one", "two", "three"], do: create_post(%{title: title})
    :ok
  end

  test "control: the search action returns every post, and limit as a control key works" do
    assert %{error: nil, result: [_, _, _]} =
             lua(~S|local r, err = blog.post.search({}) return r, err|)

    assert %{error: nil, result: [_]} =
             lua(~S|local r, err = blog.post.read({ limit = 1 }) return r, err|)
  end

  @tag bug: @bug, signature: ["input.limit was applied as the query limit"]
  test "an action argument named limit is not applied as the query limit" do
    assert %{error: nil, result: results} =
             lua(~S|local r, err = blog.post.search({ input = { limit = 1 } }) return r, err|)

    assert length(results) == 3,
           "input.limit was applied as the query limit: got #{length(results)} of 3 posts"
  end

  @tag bug: @bug, signature: ["Ash.Error.Query.InvalidLimit", "is not a valid limit"]
  test "input = { limit = 2^63 } is a rendered invalid argument error" do
    assert %{"errors" => [%{"code" => "invalid_argument", "fields" => ["limit"]}]} =
             lua_error(
               ~S|local r, err = blog.post.search({ input = { limit = 2^63 } }) return r, err|
             )
  end

  @tag bug: @bug, signature: ["Ash.Error.Query.InvalidLimit", "\"x\" is not a valid limit"]
  test "limit = \"x\" as a control key is a rendered error" do
    assert %{"errors" => [%{"code" => code}]} =
             lua_error(~S|local r, err = blog.post.read({ limit = "x" }) return r, err|)

    assert code != "unknown_error"
  end
end
