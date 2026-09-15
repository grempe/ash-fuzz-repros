defmodule Repro.Ash.SortInputShapeTest do
  @moduledoc """
  ash-project/ash: `Ash.Query.sort_input/2` with a value that is neither a
  string nor a list (`5`, `%{}`, `%{"title" => "asc"}`) crashes with
  `FunctionClauseError` in `Ash.Sort.parse_input/3`, and a list of maps
  crashes in `Ash.Resource.Info.attribute/2`. `Ash.Query.filter_input/2` puts
  an `InvalidFilterValue` on the query for an unexpected shape; sort input
  should fail the same way. Found while reproducing the ash_lua `sort = 5`
  case; it is new relative to the original fuzzing report.
  """
  use Repro.Case, async: false

  @bug "ash/sort-input-shape"

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: string and list sort inputs work, and a malformed filter input is an error" do
    assert %Ash.Query{sort: [title: :desc], errors: []} = Ash.Query.sort_input(Post, "-title")
    assert %Ash.Query{sort: [title: :asc], errors: []} = Ash.Query.sort_input(Post, ["title"])
    assert {:ok, [%Post{}]} = Post |> Ash.Query.sort_input("title") |> Ash.read()

    assert %Ash.Query{errors: [%Ash.Error.Query.InvalidFilterValue{}]} =
             Ash.Query.filter_input(Post, "title")
  end

  for input <- [5, %{}, %{"title" => "asc"}] do
    @tag bug: @bug, signature: ["FunctionClauseError", "Ash.Sort.parse_input/3"]
    test "sort_input with #{inspect(input)} puts an error on the query" do
      assert %Ash.Query{errors: [%{class: :invalid}]} =
               Ash.Query.sort_input(Post, unquote(Macro.escape(input)))
    end
  end

  @tag bug: @bug, signature: ["FunctionClauseError", "Ash.Resource.Info.attribute/2"]
  test "sort_input with a list of maps puts an error on the query" do
    assert %Ash.Query{errors: [%{class: :invalid}]} =
             Ash.Query.sort_input(Post, [%{"field" => "title"}])
  end
end
