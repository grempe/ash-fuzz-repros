defmodule Repro.Ecto.InspectQueryWithSparkRegexTypeParamTest do
  @moduledoc """
  elixir-ecto/ecto: `Inspect.Ecto.Query` renders type parameters through
  `Macro.to_string/1`. When a parameterized type carries the tuple
  `{Spark.Regex, :cache, [source, opts]}` (how Spark stores a `match:` regex
  constraint) that call raises `FunctionClauseError` in `Access.get/3` on
  Elixir 1.20, because the tuple looks like a call whose metadata is `:cache`.
  `Ecto.QueryError` and `Ecto.SubQueryError` inspect the query in their
  messages, and `Ecto.Query.CastError` inherits the crash because the planner
  builds an `Ecto.QueryError` to obtain its message. The same happens for an
  ordinary interpolated value holding such a tuple, with a built-in type and
  no parameterized type at all.

  The Ash level: AshSql copies a type's constraints into the Ecto type
  parameters of the SQL cast of a calculation, so a resource with a `:string`
  calculation constrained by `match:` turns every uncastable filter value into
  an unknown error instead of `InvalidFilterValue`.
  """
  use Repro.Case, async: false
  import Ecto.Query

  @bug "ecto/inspect-query-crashes-on-spark-regex-type-param"
  @signature ["FunctionClauseError", "Access.get/3"]

  defmodule RegexParamType do
    use Ecto.ParameterizedType
    def type(_), do: :string
    def init(opts), do: opts
    def cast(value, _), do: {:ok, value}
    def load(value, _, _), do: {:ok, value}
    def dump(value, _, _), do: {:ok, value}
  end

  @regex_param [match: {Spark.Regex, :cache, ["^[a-z]+$", []]}]

  defp query(param) do
    from(p in "posts",
      where:
        p.title == type(^"abc", {:parameterized, {RegexParamType, param}}) and
          p.id == type(^"not-a-uuid", :binary_id),
      select: p.id
    )
  end

  test "control: the same query with a plain parameter inspects and fails to cast cleanly" do
    assert inspect(query(match: "x")) =~ "from p0 in \"posts\""
    assert_raise Ecto.Query.CastError, fn -> Repro.Repo.all(query(match: "x")) end

    assert_raise Ecto.Query.CastError, fn ->
      Repro.Repo.all(
        from(p in "posts", where: p.title == type(^{1, 2, 3}, :string), select: p.id)
      )
    end
  end

  test "control: the Ash resource loads the constrained calculation and converts a bad id" do
    create_post(%{title: "one"})
    assert {:ok, [%Post{title_slug: "one"}]} = Post |> Ash.Query.load(:title_slug) |> Ash.read()

    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Post |> Ash.Query.filter(id == "not-a-uuid") |> Ash.read()
  end

  @tag bug: @bug, signature: @signature
  test "Ecto: a query whose type parameter holds the Spark regex tuple can be inspected" do
    assert inspect(query(@regex_param)) =~ "from p0 in \"posts\""
  end

  @tag bug: @bug, signature: @signature
  test "Ecto: a cast failure on such a query raises Ecto.Query.CastError" do
    assert_raise Ecto.Query.CastError, fn -> Repro.Repo.all(query(@regex_param)) end
  end

  @tag bug: @bug, signature: @signature
  test "Ecto: an interpolated three-tuple value with a built-in type raises Ecto.Query.CastError" do
    assert_raise Ecto.Query.CastError, fn ->
      Repro.Repo.all(
        from(p in "posts",
          where: p.title == type(^{Foo, :cache, ["a", []]}, :string),
          select: p.id
        )
      )
    end
  end

  @tag bug: @bug, signature: @signature
  test "Ash: loading a match-constrained string calculation keeps InvalidFilterValue for a bad id" do
    assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}} =
             Post
             |> Ash.Query.load(:title_slug)
             |> Ash.Query.filter(id == "not-a-uuid")
             |> Ash.read()
  end
end
