defmodule Repro.AshGraphql.NegativePageSizeComplexityTest do
  @moduledoc """
  ash-project/ash_graphql: with `analyze_complexity: true` on `Absinthe.Plug`,
  `AshGraphql.Graphql.Resolver.query_complexity/3` multiplies the child
  complexity by `first`, `last` or `limit` without a floor. A negative page size
  yields a negative complexity and Absinthe raises `Absinthe.AnalysisError`
  before any resolver runs, so the request is a 500. Setting `max_complexity`
  does not change that. With analysis off, `first: -1` is an unrendered
  `Spark.Options.ValidationError` (see the zero page size test), while a
  relationship field's `limit: -1` returns an empty list.
  """
  use Repro.Case, async: false

  @bug "ash_graphql/negative-page-size-complexity"
  @signature ["Absinthe.AnalysisError", "The complexity value must be a non negative integer"]

  setup do
    post = create_post(%{title: "one"})
    create_comment(post)
    :ok
  end

  test "control: positive page sizes pass complexity analysis" do
    assert {200, %{"data" => %{"listPosts" => %{"results" => [%{"comments" => [_]}]}}}} =
             graphql("{ listPosts(first: 1) { results { id comments(limit: 1) { id } } } }")
  end

  @tag bug: @bug, signature: @signature
  test "listPosts(first: -1) is a GraphQL error, not a crash" do
    assert {200, %{"errors" => [_ | _]}} = graphql("{ listPosts(first: -1) { results { id } } }")
  end

  @tag bug: @bug, signature: @signature
  test "listPosts(last: -1) is a GraphQL error, not a crash" do
    assert {200, %{"errors" => [_ | _]}} = graphql("{ listPosts(last: -1) { results { id } } }")
  end

  @tag bug: @bug, signature: @signature
  test "a relationship field with limit: -1 is a GraphQL error, not a crash" do
    assert {200, %{"errors" => [_ | _]}} =
             graphql("{ listPosts(first: 1) { results { comments(limit: -1) { id } } } }")
  end
end
