defmodule Repro.AshLua.UnrenderedQueryErrorsTest do
  @moduledoc """
  ash-project/ash_lua: `Ash.Error.Query.InvalidFilterValue`,
  `NoSuchFilterPredicate` and `NoSuchField` have no `AshLua.Error`
  implementation, so a script gets `unknown_error` with a uuid instead of a
  structured error naming the field.
  """
  use Repro.Case, async: false

  @bug "ash_lua/unrendered-query-errors"

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: a field selection mistake is a structured error" do
    assert %{
             "class" => "invalid",
             "errors" => [%{"code" => "unknown_field", "fields" => ["nope"]}]
           } =
             lua_error(~S|local r, err = blog.post.read({ fields = { "nope" } }) return r, err|)
  end

  @tag bug: @bug,
       signature: ["AshLua.Error not implemented", "Ash.Error.Query.InvalidFilterValue"]
  test "filter = { id = \"not-a-uuid\" } is rendered" do
    assert %{"errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { id = "not-a-uuid" } }) return r, err|
             )

    assert code != "unknown_error"
  end

  @tag bug: @bug,
       signature: ["AshLua.Error not implemented", "Ash.Error.Query.NoSuchFilterPredicate"]
  test "filter = { title = { nope = \"x\" } } is rendered" do
    assert %{"errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { title = { nope = "x" } } }) return r, err|
             )

    assert code != "unknown_error"
  end

  @tag bug: @bug, signature: ["AshLua.Error not implemented", "Ash.Error.Query.NoSuchField"]
  test "filter = { nope = \"x\" } is rendered" do
    assert %{"errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { nope = "x" } }) return r, err|
             )

    assert code != "unknown_error"
  end
end
