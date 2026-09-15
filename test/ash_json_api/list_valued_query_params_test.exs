defmodule Repro.AshJsonApi.ListValuedQueryParamsTest do
  @moduledoc """
  ash-project/ash_json_api: `include[]=comments`, `fields[post][]=title`,
  `page[]=1` and `page[limit][]=1` decode to lists, and the request parser
  assumes strings or maps, so the router raises (a 500). The route's own
  hrefSchema types these parameters, but includes and page params are read
  before it is validated. `sort[]=title` is validated and answers 400.
  """
  use Repro.Case, async: false

  @bug "ash_json_api/list-valued-query-params-crash"
  @signature ["FunctionClauseError", "String.split/3"]

  setup do
    post = create_post(%{title: "one"})
    create_comment(post)
    :ok
  end

  test "control: string-valued include and fields work, and a list-valued sort answers 400" do
    assert {200, %{"included" => [%{"type" => "comment"}]}} =
             json_api(:get, "/posts?include=comments")

    assert {200, %{"data" => [%{"attributes" => %{"title" => "one"}}]}} =
             json_api(:get, "/posts?fields[post]=title")

    assert {400, %{"errors" => [%{"code" => "invalid_sort"}, %{"code" => "invalid_query"}]}} =
             json_api(:get, "/posts?sort[]=title")
  end

  @tag bug: @bug, signature: @signature
  test "include[]=comments answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?include[]=comments")
  end

  @tag bug: @bug, signature: @signature
  test "fields[post][]=title answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?fields[post][]=title")
  end

  @tag bug: @bug, signature: ["BadMapError", "expected a map"]
  test "page[]=1 answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?page[]=1")
  end

  @tag bug: @bug, signature: ["FunctionClauseError", "Integer.parse/2"]
  test "page[limit][]=1 answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?page[limit][]=1")
  end
end
