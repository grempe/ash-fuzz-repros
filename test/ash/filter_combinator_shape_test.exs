defmodule Repro.Ash.FilterCombinatorShapeTest do
  @moduledoc """
  ash-project/ash: a filter combinator (`and` / `or`) whose value is not a
  non-empty list or map crashes with `FunctionClauseError` in
  `Ash.Filter.parse_and_join/3` instead of returning an invalid filter error.
  A string, nil, an integer or an empty list matches neither clause; an empty
  map matches the map clause, reduces to `[]`, and then matches neither. By
  contrast `%{"not" => "x"}` puts an `InvalidFilterValue` on the query.
  """
  use Repro.Case, async: false

  @bug "ash/filter-combinator-shape"
  @signature ["FunctionClauseError", "Ash.Filter.parse_and_join/3"]

  setup do
    %{post: create_post(%{title: "one"})}
  end

  test "control: a list-valued combinator filters normally", %{post: post} do
    query = Ash.Query.filter_input(Post, %{"and" => [%{"title" => "one"}]})
    assert {:ok, [%Post{id: id}]} = Ash.read(query)
    assert id == post.id
  end

  test "control: a malformed `not` puts an InvalidFilterValue on the query" do
    assert %Ash.Query{errors: [%Ash.Error.Query.InvalidFilterValue{}]} =
             Ash.Query.filter_input(Post, %{"not" => "x"})
  end

  test "control: JSON:API list-valued combinator answers 200" do
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?filter[and][0][title]=one")
  end

  for shape <- [
        %{"and" => "x"},
        %{"or" => ""},
        %{"or" => %{}},
        %{"or" => []},
        %{"or" => nil},
        %{"and" => 5}
      ] do
    @tag bug: @bug, signature: @signature
    test "filter_input with #{inspect(shape)} returns an invalid filter error" do
      query = Ash.Query.filter_input(Post, unquote(Macro.escape(shape)))
      assert {:error, %Ash.Error.Invalid{}} = Ash.read(query)
    end
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[and]=x answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?filter[and]=x")
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[or]= answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?filter[or]=")
  end
end
