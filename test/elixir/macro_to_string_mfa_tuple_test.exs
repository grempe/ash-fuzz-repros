defmodule Repro.Elixir.MacroToStringMfaTupleTest do
  @moduledoc """
  elixir-lang/elixir: `Macro.to_string({Foo, :cache, ["a", []]})` raises
  `FunctionClauseError` in `Access.get/3` (Elixir 1.18 through 1.20 and main).
  `Code.Normalizer` treats any three-tuple with a list third element as a call
  and reads `meta[:line]` on the atom `:cache`. The documentation says invalid
  nodes are inspected to aid debugging, and `{1, 2, 3}` is; this shape is not.
  Ecto passes such tuples to `Macro.to_string/1` when inspecting a query (see
  the ecto repro), which is reported separately.
  """
  use ExUnit.Case, async: false

  @bug "elixir/macro-to-string-mfa-tuple"
  @signature ["FunctionClauseError", "Access.get/3"]

  test "control: a call with keyword metadata renders, and other non-AST tuples are inspected" do
    assert Macro.to_string({Foo, [], ["a", []]}) == ~S|Elixir.Foo("a", [])|
    assert Macro.to_string({1, 2, 3}) == "{1, 2, 3}"
  end

  @tag bug: @bug, signature: @signature
  test "a three-tuple with an atom in the metadata position is inspected" do
    assert Macro.to_string({Foo, :cache, ["a", []]}) == ~S|{Foo, :cache, ["a", []]}|
  end
end
