defmodule Repro.AshGraphql.ZeroPageSizeTest do
  @moduledoc """
  ash-project/ash_graphql: `first: 0` and `last: 0` are mapped onto Ash's page
  `limit`, which must be a positive integer. The resulting
  `Spark.Options.ValidationError` is wrapped as `Ash.Error.Unknown`, which has
  no GraphQL rendering, so the client gets "Something went wrong". A
  relationship field's `limit: 0` legitimately returns an empty list.
  """
  use Repro.Case, async: false

  @bug "ash_graphql/zero-page-size-unrendered"
  @signature ["Spark.Options.ValidationError", "expected positive integer, got: 0"]

  setup do
    post = create_post(%{title: "one"})
    create_comment(post)
    :ok
  end

  test "control: a relationship field with limit: 0 returns an empty list" do
    assert {200, %{"data" => %{"listPosts" => %{"results" => [%{"comments" => []}]}}}} =
             graphql("{ listPosts(first: 1) { results { comments(limit: 0) { id } } } }")
  end

  @tag bug: @bug, signature: @signature
  test "listPosts(first: 0) is a rendered error" do
    assert {200, %{"errors" => [%{"code" => _}]}} =
             graphql("{ listPosts(first: 0) { results { id } } }")
  end

  @tag bug: @bug, signature: @signature
  test "listPosts(last: 0, before: cursor) is a rendered error" do
    assert {200, %{"data" => %{"listPosts" => %{"endKeyset" => cursor}}}} =
             graphql("{ listPosts(first: 1) { results { id } endKeyset } }")

    assert {200, %{"errors" => [%{"code" => _}]}} =
             graphql(~s|{ listPosts(last: 0, before: "#{cursor}") { results { id } } }|)
  end
end
