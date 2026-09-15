defmodule Repro.AshLua.NestedErrorTableTest do
  @moduledoc """
  ash-project/ash_lua: when a script returns the error table from a failed
  call, `AshLua.Eval.run/2` converts it only at its top level. Nested Lua
  tables, including the `errors` list, stay as lists of `{key, value}` tuples,
  so the result cannot be JSON encoded. The result slot is converted at every
  depth.
  """
  use Repro.Case, async: false

  @bug "ash_lua/returned-error-table-converted-only-at-top-level"

  @script ~S|local r, err = blog.post.read({ filter = { title = { nope = "x" } } }) return r, err|

  test "control: a returned result table is converted at every depth" do
    assert %{error: nil, result: %{"a" => %{"b" => [1, 2]}}} =
             lua(~S|return { a = { b = { 1, 2 } } }|)

    assert {:ok, _} = Jason.encode(lua(~S|return { a = { b = { 1, 2 } } }|))
  end

  @tag bug: @bug, signature: ["{1,", "{\"code\", \"unknown_error\"}"]
  test "the errors list of a returned error table is a list of maps" do
    assert %{error: %{"errors" => [%{"code" => _} | _]}} = lua(@script)
  end

  @tag bug: @bug, signature: ["Protocol.UndefinedError", "protocol: Jason.Encoder"]
  test "the run result can be JSON encoded" do
    assert {:ok, _} = Jason.encode(lua(@script))
  end
end
