defmodule Repro.AshGraphql.NullBooleanFilterTest do
  @moduledoc """
  ash-project/ash_graphql: a null or empty boolean combinator in a filter
  (`{and: null}`, `{or: null}`, `{not: null}`, `{not: []}`) has no matching
  clause in `AshGraphql.Graphql.FilterHandlers.process_boolean_filter/5`, so the
  resolver raises and the client gets "Something went wrong". A `not` list with
  two elements crashes the same way. The generated schema types `and`, `or` and
  `not` as a nullable `[PostFilterInput!]`, so all of these pass validation.

  Fixed in ash_graphql 1.12.0 (ash-project/ash_graphql#475). The bug tests pass on the pinned release and are
  kept as regression checks; `signature:` records how they used to fail.
  """
  use Repro.Case, async: false

  @moduletag fixed_in: "ash_graphql 1.12.0"

  @bug "ash_graphql/null-boolean-filter-crash"
  @signature [
    "FunctionClauseError",
    "AshGraphql.Graphql.FilterHandlers.process_boolean_filter/5"
  ]

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: list-valued combinators filter normally" do
    assert {200, %{"data" => %{"listPosts" => %{"results" => [_]}}}} =
             graphql(~S|{ listPosts(filter: {and: [{title: {eq: "one"}}]}) { results { id } } }|)

    assert {200, %{"data" => %{"listPosts" => %{"results" => [_]}}}} =
             graphql(~S|{ listPosts(filter: {not: [{title: {eq: "x"}}]}) { results { id } } }|)
  end

  for filter <- [
        "{and: null}",
        "{or: null}",
        "{not: null}",
        "{not: []}",
        ~S|{not: [{title: {eq: "x"}}, {score: {eq: 9}}]}|
      ] do
    @tag bug: @bug, signature: @signature
    test "listPosts(filter: #{filter}) does not crash" do
      assert {200, %{"data" => %{"listPosts" => %{"results" => [_ | _]}}}} =
               graphql("{ listPosts(filter: #{unquote(filter)}) { results { id } } }")
    end
  end
end
