defmodule Repro.Ash.IsNilNonBooleanTest do
  @moduledoc """
  ash-project/ash: `is_nil` with a value that is not a boolean. The cast failure
  in `Ash.Query.Operator.cast_one/2` is a bare string, so Ash can only wrap it as
  `Ash.Error.Unknown.UnknownError`. JSON:API answers 500.

  Fixed in ash 3.33.7 (commit 34e5e5e, the fix for ash-project/ash#2952). The bug tests pass on the pinned release and are
  kept as regression checks; `signature:` records how they used to fail.
  """
  use Repro.Case, async: false

  @moduletag fixed_in: "ash 3.33.7"

  @bug "ash/is-nil-non-boolean-value"
  @signature ["Could not cast", "as :boolean", "Ash.Error.Unknown"]

  setup do
    create_post(%{title: "one"})
    :ok
  end

  test "control: is_nil with a boolean string filters normally" do
    query = Ash.Query.filter_input(Post, %{"title" => %{"is_nil" => "false"}})
    assert {:ok, [%Post{}]} = Ash.read(query)
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?filter[title][is_nil]=false")
  end

  @tag bug: @bug, signature: @signature
  test "filter_input is_nil: \"maybe\" returns InvalidFilterValue" do
    query = Ash.Query.filter_input(Post, %{"title" => %{"is_nil" => "maybe"}})

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(query)
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[title][is_nil]=maybe answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?filter[title][is_nil]=maybe")
  end
end
