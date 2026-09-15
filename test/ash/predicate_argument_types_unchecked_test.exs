defmodule Repro.Ash.PredicateArgumentTypesUncheckedTest do
  @moduledoc """
  ash-project/ash: when parsing an input filter, a predicate is selected by
  name and a referenced attribute is never compared to the predicate's declared
  argument types. `range_overlaps`, `range_adjacent` and `range_contains` on a
  text attribute, and `contains` on an integer attribute, all parse and reach
  Postgres, which rejects the operator (`operator does not exist: text && unknown`,
  `bigint ~~ unknown`). The three range predicates also declare their
  argument types as `[:any, :same]` (`[:any, :any]` for contains), which is
  why AshGraphql's filter input types list them on every field; that
  introspection test is tagged with this bug as evidence.
  """
  use Repro.Case, async: false

  @bug "ash/predicate-argument-types-unchecked"
  @signature ["Postgrex.Error", "operator does not exist:"]

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: a text predicate filters normally" do
    query = Ash.Query.filter_input(Post, %{"title" => %{"contains" => "on"}})
    assert {:ok, [%Post{}]} = Ash.read(query)
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?filter[title][contains]=on")

    assert {200, %{"data" => %{"listPosts" => %{"results" => [_]}}}} =
             graphql(~S|{ listPosts(filter: {title: {contains: "on"}}) { results { id } } }|)
  end

  for predicate <- ["range_overlaps", "range_adjacent", "range_contains"] do
    @tag bug: @bug, signature: @signature
    test "filter_input #{predicate} on a text attribute returns an invalid filter error" do
      query = Ash.Query.filter_input(Post, %{"title" => %{unquote(predicate) => "x"}})
      assert {:error, %Ash.Error.Invalid{}} = Ash.read(query)
    end
  end

  @tag bug: @bug, signature: @signature
  test "filter_input contains on an integer attribute returns an invalid filter error" do
    query = Ash.Query.filter_input(Post, %{"score" => %{"contains" => "x"}})
    assert {:error, %Ash.Error.Invalid{}} = Ash.read(query)
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[title][range_overlaps]=x answers 400" do
    assert {400, %{"errors" => [_ | _]}} =
             json_api(:get, "/posts?filter[title][range_overlaps]=x")
  end

  @tag bug: @bug, signature: @signature
  test "GraphQL listPosts(filter: {title: {rangeOverlaps: \"x\"}}) returns a rendered error" do
    assert {200, %{"errors" => [%{"code" => code}]}} =
             graphql(~S|{ listPosts(filter: {title: {rangeOverlaps: "x"}}) { results { id } } }|)

    assert code != "something_went_wrong"
  end
end
