defmodule Repro.Ash.InvalidPageOptionsTest do
  @moduledoc """
  ash-project/ash: invalid `page` options from client input are returned as
  `Ash.Error.Unknown` wrapping a `Spark.Options.ValidationError` rather than an
  invalid-class error: `after` plus `offset` on an action with keyset and
  offset pagination, a limit of 0, -1 or "x", or a negative offset. JSON:API
  answers 500 for all of them. A non-list `page` value raises.
  """
  use Repro.Case, async: false

  @bug "ash/invalid-page-options-unrendered"
  @signature ["Spark.Options.ValidationError", "invalid value for :page option"]

  setup do
    create_post(%{title: "one"})
    create_post(%{title: "two"})
    :ok
  end

  test "control: keyset and offset pages each work alone" do
    assert {:ok, %Ash.Page.Offset{results: [first]}} = Ash.read(Post, page: [limit: 1, offset: 0])
    cursor = first.__metadata__.keyset
    assert {:ok, %Ash.Page.Keyset{results: [_]}} = Ash.read(Post, page: [limit: 1, after: cursor])
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?page[limit]=1&page[offset]=0")
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?page[limit]=1&page[after]=#{cursor}")
  end

  @tag bug: @bug, signature: @signature
  test "Ash.read with page: [after: \"x\", offset: 1] returns Ash.Error.Invalid" do
    assert {:error, %Ash.Error.Invalid{}} = Ash.read(Post, page: [after: "x", offset: 1])
  end

  for page <- [[limit: 0], [limit: -1], [limit: "x"], [limit: 1, offset: -1]] do
    @tag bug: @bug, signature: @signature
    test "Ash.read with page: #{inspect(page)} returns Ash.Error.Invalid" do
      assert {:error, %Ash.Error.Invalid{}} = Ash.read(Post, page: unquote(page))
    end
  end

  @tag bug: @bug, signature: ["FunctionClauseError", "Access.get/3"]
  test "Ash.read with page: \"x\" returns Ash.Error.Invalid instead of raising" do
    assert {:error, %Ash.Error.Invalid{}} = Ash.read(Post, page: "x")
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API page[after]=x&page[offset]=1 answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?page[after]=x&page[offset]=1")
  end
end
