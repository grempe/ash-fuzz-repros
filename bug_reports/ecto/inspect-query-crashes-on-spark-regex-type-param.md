# Inspecting a query that holds a three-tuple such as {Foo, :cache, [...]} raises, so Ecto.Query.CastError cannot be raised

Versions: ecto 3.14.2, ecto_sql 3.14.0, postgrex 0.22.4, Elixir 1.20.1 on OTP 29. Present on the default branch at `24f914a (master)` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

No repo or database is needed for `inspect/1`:
```elixir
defmodule P do
  use Ecto.ParameterizedType
  def type(_), do: :string
  def init(opts), do: opts
  def cast(v, _), do: {:ok, v}
  def load(v, _, _), do: {:ok, v}
  def dump(v, _, _), do: {:ok, v}
end

import Ecto.Query
type = {:parameterized, {P, [match: {Foo, :cache, ["^[a-z]+$", []]}]}}
inspect(from p in "posts", where: p.title == type(^"abc", ^type), select: p.id)
```
The same tuple in an ordinary interpolated value reproduces it with a built-in type and no parameterized type:
```elixir
Repo.all(from p in "posts", where: p.title == type(^{Foo, :cache, ["a", []]}, :string))
```
The three-tuple is how Spark stores a `match:` regex constraint (`{Spark.Regex, :cache, [source, opts]}`) and Ash's SQL layer copies a type's constraints into the Ecto type parameters, which is how it was hit; neither library is needed to reproduce.

## Observed

```
inspect(query)
# "#Inspect.Error<got FunctionClauseError with message: no function clause matching in Access.get/3 ...>"
Repo.all(query)
# ** (FunctionClauseError) no function clause matching in Access.get/3
```
`Repo.all/1` should have raised `Ecto.Query.CastError` (as it does for `^{1, 2, 3}` or `[match: "x"]`); instead the message construction of `Ecto.QueryError` crashes. Params held in a map rather than a keyword list do not reproduce. On Elixir 1.18 through 1.20, `Macro.to_string({Foo, :cache, ["a", []]})` raises the same `FunctionClauseError` (reported to Elixir separately; this report does not depend on it).

## Expected

`inspect/1` succeeds and `Ecto.Query.CastError` is raised normally.

## Failure point

`Inspect.Ecto.Query.expr/3`, [lib/ecto/query/inspect.ex#L260-L267](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/query/inspect.ex#L260-L267), and the interpolated-value clause at L307-L318, both ending in `Macro.to_string/1`; `Ecto.QueryError` and `Ecto.SubQueryError` interpolate the inspected query at [lib/ecto/exceptions.ex#L36](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/exceptions.ex#L36) and L78, and `Ecto.Query.Planner.cast_param/6` builds a `QueryError` for the `CastError` message at [lib/ecto/query/planner.ex#L1153-L1161](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/query/planner.ex#L1153-L1161).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ectoinspect-query-crashes-on-spark-regex-type-param
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ecto/inspect_query_with_spark_regex_type_param_test.exs
* Run: `mix setup && mix test test/ecto/inspect_query_with_spark_regex_type_param_test.exs` in https://github.com/grempe/ash-fuzz-repros
