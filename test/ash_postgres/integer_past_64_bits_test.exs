defmodule Repro.AshPostgres.IntegerPast64BitsTest do
  @moduledoc """
  ash-project/ash_postgres: an `:integer` value outside the `bigint` range is
  an arbitrary-precision Elixir integer for Ash (correct for data layers with
  no 64-bit limit), and Postgrex raises `DBConnection.EncodeError` when it
  encodes the parameter. `handle_raised_error/4` has no clause for that error,
  so a read or a create returns `Ash.Error.Unknown` and JSON:API answers 500.
  """
  use Repro.Case, async: false

  @bug "ash_postgres/integer-past-64-bits-unconverted"
  @signature ["DBConnection.EncodeError", "Postgrex expected an integer in"]

  @too_big 9_223_372_036_854_775_808

  setup do
    create_post(%{title: "one", score: 1})
    :ok
  end

  test "control: an in-range integer filters and stores normally" do
    assert {:ok, %Post{score: 2}} = Ash.create(Post, %{title: "two", score: 2})
    assert {:ok, [%Post{}]} = Post |> Ash.Query.filter(score == 1) |> Ash.read()
    assert {:ok, [%Post{}]} = Post |> Ash.Query.filter(score in [1]) |> Ash.read()
    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?filter[score][eq]=1")
  end

  @tag bug: @bug, signature: @signature
  test "score == 2^63 returns InvalidFilterValue" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Post |> Ash.Query.filter(score == ^@too_big) |> Ash.read()
  end

  @tag bug: @bug, signature: @signature
  test "score in [2^63] returns InvalidFilterValue" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Post |> Ash.Query.filter(score in ^[@too_big]) |> Ash.read()
  end

  @tag bug: @bug, signature: @signature
  test "filter_input with a 20-digit string in `in` returns InvalidFilterValue" do
    query = Ash.Query.filter_input(Post, %{"score" => %{"in" => ["-99999999999999999999"]}})

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(query)
  end

  @tag bug: @bug, signature: @signature
  test "Ash.create with score 2^63 returns an invalid-class error" do
    assert {:error, %Ash.Error.Invalid{}} = Ash.create(Post, %{title: "big", score: @too_big})
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[score][eq]=9223372036854775808 answers 400" do
    assert {400, %{"errors" => [_ | _]}} =
             json_api(:get, "/posts?filter[score][eq]=9223372036854775808")
  end
end
