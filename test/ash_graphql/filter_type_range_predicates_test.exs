defmodule Repro.AshGraphql.FilterTypeRangePredicatesTest do
  @moduledoc """
  ash-project/ash_graphql: the generated filter input type for a text field
  advertises `rangeOverlaps`, `rangeAdjacent` and `rangeContains`, because the
  schema lists every predicate whose argument types allow `:any`. Evidence for
  the Ash report `ash/predicate-argument-types-unchecked`; ash_graphql renders
  Ash's declarations faithfully, so no separate report is filed.
  """
  use Repro.Case, async: false

  @bug "ash/predicate-argument-types-unchecked"
  @signature ["rangeOverlaps"]
  @range_predicates ["rangeOverlaps", "rangeAdjacent", "rangeContains"]

  defp title_filter_fields do
    assert {200, %{"data" => %{"__type" => %{"inputFields" => fields}}}} =
             graphql(~S|{ __type(name: "PostFilterTitle") { inputFields { name } } }|)

    Enum.map(fields, & &1["name"])
  end

  test "control: the text filter type lists the text predicates" do
    fields = title_filter_fields()
    assert "eq" in fields
    assert "contains" in fields
  end

  @tag bug: @bug, signature: @signature
  test "the text filter type does not list range predicates" do
    fields = title_filter_fields()
    assert fields -- @range_predicates == fields
  end
end
