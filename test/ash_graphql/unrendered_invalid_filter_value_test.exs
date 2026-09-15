defmodule Repro.AshGraphql.UnrenderedInvalidFilterValueTest do
  @moduledoc """
  ash-project/ash_graphql: `Ash.Error.Query.InvalidFilterValue` has no
  `AshGraphql.Error` implementation, so `getPost(id: "not-a-uuid")` and
  `listPosts(filter: {id: {eq: "not-a-uuid"}})` answer "Something went wrong"
  instead of an `invalid_filter_value` error.
  """
  use Repro.Case, async: false

  @bug "ash_graphql/unrendered-invalid-filter-value"
  @signature ["AshGraphql.Error not implemented", "Ash.Error.Query.InvalidFilterValue"]

  setup do
    %{post: create_post(%{title: "one"})}
  end

  test "control: valid and unknown ids render normally", %{post: post} do
    assert {200, %{"data" => %{"getPost" => %{"id" => _}}}} =
             graphql(~s|{ getPost(id: "#{post.id}") { id } }|)

    assert {200, %{"data" => %{"getPost" => nil}}} =
             graphql(~s|{ getPost(id: "#{Ash.UUID.generate()}") { id } }|)
  end

  @tag bug: @bug, signature: @signature
  test "getPost(id: \"not-a-uuid\") renders invalid_filter_value" do
    assert {200, %{"errors" => [%{"code" => "invalid_filter_value"}]}} =
             graphql(~S|{ getPost(id: "not-a-uuid") { id } }|)
  end

  @tag bug: @bug, signature: @signature
  test "listPosts(filter: {id: {eq: \"not-a-uuid\"}}) renders invalid_filter_value" do
    assert {200, %{"errors" => [%{"code" => "invalid_filter_value"}]}} =
             graphql(~S|{ listPosts(filter: {id: {eq: "not-a-uuid"}}) { results { id } } }|)
  end
end
