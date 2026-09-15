defmodule Repro.AshPostgres.UncastableFilterValueConversionTest do
  @moduledoc """
  ash-project/ash_postgres: a filter value that Ecto cannot cast (a UUID primary
  key compared to `"not-a-uuid"`) raises `Ecto.Query.CastError` while Ecto plans
  the query. `AshPostgres.DataLayer.run_query/2` rescues that and converts it to
  `Ash.Error.Query.InvalidFilterValue`. The aggregate and lateral-join callbacks
  have no rescue, and `handle_raised_error/4` does not unwrap an
  `Ecto.SubQueryError` that carries the cast error, so the conversion happens
  only where a rescue exists and the error is a bare cast error.
  """
  use Repro.Case, async: false

  @bug "ash_postgres/uncastable-filter-value-conversion"
  @cast_error ["Ecto.Query.CastError", "not-a-uuid"]
  @subquery_error ["Ecto.SubQueryError", "Ecto.Query.CastError", "not-a-uuid"]

  # Two parents, so that a limited relationship load uses a lateral join.
  setup do
    p1 = create_post(%{title: "one"})
    p2 = create_post(%{title: "two"})
    c1 = create_comment(p1)
    c2 = create_comment(p2)
    %{posts: [p1, p2], comments: [c1, c2]}
  end

  defp bad_id, do: Ash.Query.filter(Post, id == "not-a-uuid")

  defp bad_comment_load(query \\ Post) do
    Ash.Query.load(query,
      comments: Comment |> Ash.Query.filter(id == "not-a-uuid") |> Ash.Query.limit(1)
    )
  end

  test "control: a plain read converts the cast error to InvalidFilterValue" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(bad_id())
  end

  test "control: count, exists, aggregate and a limited count work with a valid id",
       %{posts: [p1 | _]} do
    query = Ash.Query.filter(Post, id == ^p1.id)
    assert {:ok, 1} = Ash.count(query)
    assert {:ok, true} = Ash.exists(query)
    assert {:ok, %{m: %DateTime{}}} = Ash.aggregate(query, {:m, :max, field: :inserted_at})
    assert {:ok, 1} = query |> Ash.Query.limit(1) |> Ash.count()
  end

  test "control: a limited relationship load with one parent converts cleanly",
       %{posts: [p1 | _]} do
    query = Post |> Ash.Query.filter(id == ^p1.id) |> bad_comment_load()

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(query)
  end

  test "control: the relationship surfaces work with a valid id", %{comments: [c1 | _]} do
    query =
      Ash.Query.load(Post,
        comments: Comment |> Ash.Query.filter(id == ^c1.id) |> Ash.Query.limit(1)
      )

    assert {:ok, [%Post{}, %Post{}]} = Ash.read(query)

    query = Ash.Query.filter_input(Post, %{comments: %{id: %{eq: c1.id}}})
    assert {:ok, %Ash.Page.Offset{results: [%Post{}]}} = Ash.read(query, page: [limit: 5])
  end

  @tag bug: @bug, signature: @cast_error
  test "6a: Ash.count returns InvalidFilterValue instead of raising" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.count(bad_id())
  end

  @tag bug: @bug, signature: @cast_error
  test "6a: Ash.exists returns InvalidFilterValue instead of raising" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.exists(bad_id())
  end

  @tag bug: @bug, signature: @cast_error
  test "6a: Ash.aggregate returns InvalidFilterValue instead of raising" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.aggregate(bad_id(), {:m, :max, field: :inserted_at})
  end

  @tag bug: @bug, signature: @subquery_error
  test "6b: Ash.count with a limit returns InvalidFilterValue instead of raising SubQueryError" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             bad_id() |> Ash.Query.limit(1) |> Ash.count()
  end

  @tag bug: @bug, signature: @subquery_error
  test "6c: a limited relationship load across two parents returns InvalidFilterValue" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(bad_comment_load())
  end

  @tag bug: @bug, signature: @subquery_error
  test "6d: a to-many relationship filter on a paginated read returns InvalidFilterValue" do
    query = Ash.Query.filter_input(Post, %{comments: %{id: %{eq: "not-a-uuid"}}})

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Ash.read(query, page: [limit: 5])
  end

  test "control: a bulk update filtered by an uncastable id converts cleanly" do
    result =
      Post
      |> Ash.Query.filter(id == "not-a-uuid")
      |> Ash.bulk_update(:update, %{title: "two"}, return_errors?: true, strategy: :atomic)

    assert %Ash.BulkResult{
             status: :error,
             errors: [%Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}]
           } = result
  end

  @tag bug: @bug, signature: @subquery_error
  test "6e via JSON:API: PATCH /posts/not-a-uuid answers 400" do
    assert {400, %{"errors" => [_ | _]}} =
             json_api(:patch, "/posts/not-a-uuid", %{
               data: %{type: "post", id: "not-a-uuid", attributes: %{title: "two"}}
             })
  end

  @tag bug: @bug, signature: ["cannot be cast to type #Ash.Type.UUID.EctoType"]
  test "6a via ash_lua: a count operation returns a structured error" do
    assert %{"class" => "invalid", "errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { id = "not-a-uuid" }, operation = "count" }) return r, err|
             )

    assert code != "lua_error"
  end

  @tag bug: @bug, signature: ["cannot be cast to type #Ash.Type.UUID.EctoType"]
  test "6a via ash_lua: an exists operation returns a structured error" do
    assert %{"class" => "invalid", "errors" => [%{"code" => code}]} =
             lua_error(
               ~S|local r, err = blog.post.read({ filter = { id = "not-a-uuid" }, operation = "exists" }) return r, err|
             )

    assert code != "lua_error"
  end

  @tag bug: @bug, signature: @subquery_error
  test "6c via GraphQL: a limited relationship field with a bad filter leaves no cast error in the log" do
    {response, log} =
      with_log(fn ->
        graphql(
          ~S|{ listPosts(first: 5) { results { comments(filter: {id: {eq: "not-a-uuid"}}, limit: 1) { id } } } }|
        )
      end)

    assert {200, %{"errors" => [_]}} = response
    refute log =~ "Ecto.Query.CastError", log
  end

  @tag bug: @bug, signature: @subquery_error
  test "6d via GraphQL: a to-many relationship filter on a paginated query leaves no cast error in the log" do
    {response, log} =
      with_log(fn ->
        graphql(
          ~S|{ listPosts(first: 5, filter: {comments: {id: {eq: "not-a-uuid"}}}) { results { id } } }|
        )
      end)

    assert {200, %{"errors" => [_]}} = response
    refute log =~ "Ecto.Query.CastError", log
  end

  # The three GraphQL tests assert that no Ecto cast error reached AshGraphql,
  # which logs the error it could not render. A returned InvalidFilterValue is
  # rendered as "Something went wrong" too, by the separate
  # ash_graphql/unrendered-invalid-filter-value bug, so the rendered message
  # cannot tell the two apart.
  #
  # With async enabled (the default) the page query fails first with a clean
  # InvalidFilterValue and the count task is never awaited, so the two count
  # requests then fail for the transports' rendering of that error instead.
  @tag bug: @bug, signature: @cast_error
  test "6a via GraphQL count with disable_async?: true leaves no cast error in the log" do
    {response, log} =
      with_log(fn ->
        with_disabled_async(fn ->
          graphql(~S|{ listPosts(first: 1, filter: {id: {eq: "not-a-uuid"}}) { count } }|)
        end)
      end)

    assert {200, %{"errors" => [_]}} = response
    refute log =~ "Ecto.Query.CastError", log
  end

  @tag bug: @bug, signature: @cast_error
  test "6a via JSON:API page[count]=true with disable_async?: true answers 400" do
    assert {400, %{"errors" => [_ | _]}} =
             with_disabled_async(fn ->
               json_api(:get, "/posts?filter[id]=not-a-uuid&page[count]=true")
             end)
  end
end
