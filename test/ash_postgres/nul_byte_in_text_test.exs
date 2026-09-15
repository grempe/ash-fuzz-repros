defmodule Repro.AshPostgres.NulByteInTextTest do
  @moduledoc """
  ash-project/ash_postgres: Postgres `text` cannot store a NUL byte, so creating
  or filtering with `"a\\0b"` raises `Postgrex.Error` 22021
  (`character_not_in_repertoire`). AshPostgres returns it as an unknown-class
  error, so every surface reports an unknown error. The Postgres error names
  no column, so the expectation is an invalid-class error; attributing it to
  the attribute is possible only by inspecting the changeset. Postgrex considers sanitising the application's job
  (elixir-ecto/postgrex#568). Invalid UTF-8 fails the same way; only a Lua
  literal can carry it, since JSON transports refuse it on decoding.
  """
  use Repro.Case, async: false

  @bug "ash_postgres/nul-byte-in-text"
  @signature ["Postgrex.Error", "22021", "character_not_in_repertoire"]

  @nul "a" <> <<0>> <> "b"

  test "control: an ordinary title is created and filtered on every surface" do
    assert {:ok, %Post{title: "a b"}} = Ash.create(Post, %{title: "a b"})
    assert {:ok, [%Post{}]} = Post |> Ash.Query.filter(title == "a b") |> Ash.read()

    assert {201, %{"data" => %{"id" => _}}} =
             json_api(:post, "/posts", %{data: %{type: "post", attributes: %{title: "a c"}}})

    assert {200, %{"data" => [_]}} = json_api(:get, "/posts?filter[title]=a%20c")

    assert {200, %{"data" => %{"createPost" => %{"result" => %{"id" => _}}}}} =
             graphql(
               "mutation ($input: CreatePostInput!) { createPost(input: $input) { result { id } errors { message } } }",
               %{"input" => %{"title" => "a d"}}
             )

    assert %{error: nil, result: %{"id" => _}} =
             lua(~S|local r, err = blog.post.create({ input = { title = "a e" } }) return r, err|)
  end

  @tag bug: @bug, signature: @signature
  test "Ash.create with a NUL byte returns an invalid attribute error" do
    assert {:error, %Ash.Error.Invalid{}} = Ash.create(Post, %{title: @nul})
  end

  @tag bug: @bug, signature: @signature
  test "a filter with a NUL byte returns InvalidFilterValue" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Post |> Ash.Query.filter(title == @nul) |> Ash.read()
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API POST /posts with a NUL byte answers 400" do
    assert {400, %{"errors" => [_ | _]}} =
             json_api(:post, "/posts", %{data: %{type: "post", attributes: %{title: @nul}}})
  end

  @tag bug: @bug, signature: @signature
  test "JSON:API filter[title]=a%00b answers 400" do
    assert {400, %{"errors" => [_ | _]}} = json_api(:get, "/posts?filter[title]=a%00b")
  end

  @tag bug: @bug, signature: @signature
  test "GraphQL createPost with a NUL byte in a variable is a rendered field error" do
    assert {200, %{"data" => %{"createPost" => %{"errors" => [%{"message" => message}]}}}} =
             graphql(
               "mutation ($input: CreatePostInput!) { createPost(input: $input) { result { id } errors { message } } }",
               %{"input" => %{"title" => @nul}}
             )

    refute message =~ "went wrong"
  end

  @tag bug: @bug, signature: @signature
  test "GraphQL createPost with a NUL escape in the document is a rendered field error" do
    assert {200, %{"data" => %{"createPost" => %{"errors" => [%{"message" => message}]}}}} =
             graphql(
               ~S|mutation { createPost(input: {title: "a\u0000b"}) { result { id } errors { message } } }|
             )

    refute message =~ "went wrong"
  end

  @tag bug: @bug, signature: @signature
  test "ash_lua create with a NUL byte returns a structured invalid error" do
    assert %{"class" => "invalid", "errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.create({ input = { title = "a\0b" } }) return r, err|
             )

    assert code != "unknown_error"
  end

  @tag bug: @bug, signature: ["Postgrex.Error", "22021", "0xff"]
  test "ash_lua create with invalid UTF-8 returns a structured invalid error" do
    assert %{"class" => "invalid", "errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.create({ input = { title = "a\255b" } }) return r, err|
             )

    assert code != "unknown_error"
  end
end
