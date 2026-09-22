# ash-fuzz-repros

Minimal, deterministic reproductions of upstream bugs found by property-based
fuzzing of an Ash application. Each bug has its own test file. The test asserts
the correct behaviour, so while the bug is open it fails on the pinned versions,
and it fails for exactly the reason documented below. Once a release fixes a
bug, the pin moves to that release, the test is tagged `fixed_in:` and it is
kept as a passing regression check. `mix repros.check` verifies both.

All 22 bugs were filed upstream on 2026-09-15. As of 2026-09-22, 9 are fixed in
a release, 8 are fixed on the upstream default branch but not released, and 5
are open. The table under [Bugs](#bugs) has the status of each.

Nothing here is specific to the application the bugs were found in: one Mix
project, one Ash domain (`Repro.Blog`), two resources (`Repro.Post`,
`Repro.Comment`), no authorization, no policies, default error rendering, and a
plain `Plug.Router` driven with `Plug.Test` (no server).

## Versions

Every direct dependency is pinned to the newest exact release in `mix.exs`
(checked 2026-09-21). "Found on" is the release each library was at when the
bugs were found and filed; the links in the sections below point at those
releases.

| Library | Pinned | Found on |
|---|---|---|
| ash | 3.33.9 | 3.33.3 |
| ash_postgres | 2.13.1 | 2.13.1 |
| ash_sql | 0.7.6 | 0.7.3 |
| ash_json_api | 1.7.1 | 1.7.1 |
| ash_graphql | 1.12.0 | 1.11.0 |
| ash_lua | 0.2.2 | 0.2.2 |
| ash_ai | 1.1.0 | 1.0.3 |
| absinthe | 1.12.0 | 1.12.0 |
| absinthe_plug | 1.5.10 | 1.5.10 |
| ecto | 3.14.2 | 3.14.2 |
| ecto_sql | 3.14.0 | 3.14.0 |
| postgrex | 0.22.4 | 0.22.4 |
| spark | 2.7.3 | 2.7.2 |
| lua | 1.0.2 | 1.0.2 |
| Elixir / OTP | 1.20.1 / 29 | 1.20.1 / 29 |
| PostgreSQL | 18.6 | 18.6 |

When the bugs were filed, upstream default branches were checked read-only on
2026-09-15 at these commits (the "Default branch" line in each section refers
to them): ash `a7a5105`, ash_postgres `97ffea9`, ash_sql `b5ae09a`,
ash_json_api `fe58c33`, ash_graphql `fd31401`, ash_lua `2fb5f49`,
ash_ai `158d5e9`, absinthe `1372ceb`, ecto `24f914a` (master), spark
`d1bc299`, elixir `39164ec`.

## Running

Requirements: Elixir 1.20.1 on OTP 29 and PostgreSQL 16 or newer (see
`.tool-versions`). The project expects a local server at `localhost:5432` with
user `postgres` and password `postgres`, and uses its own database,
`ash_fuzz_repros_test`. Set `DATABASE_URL` to use something else.

```sh
mix setup          # deps.get, create the database, migrate
mix test           # open bug tests fail; fixed bug tests and controls pass
mix repros.check   # runs the suite and checks every expectation
```

`mix repros.check` prints one row per bug and exits non-zero if an open bug
test passed, a failure's output lacks its documented signature, a test tagged
`fixed_in:` failed, or a control test failed. Pass `--seed N` to pin the order. The suite is deterministic: fixed
inputs, `async: false`, the Ecto SQL sandbox, and data created in each test's
setup.

To see one bug, run its file, for example
`mix test test/ash/filter_combinator_shape_test.exs`. Each file has a passing
control test and one or more bug tests. The bug tests are tagged
`bug: "<upstream_repo>/<slug>"` and `signature: [...]`, and while a bug is open
the signature strings must appear in the failure output (including captured
logs). A bug test that a pinned release has fixed also carries
`fixed_in: "<library> <version>"`; it must pass, and its signature stays as a
record of how it used to fail.

The migrations in `priv/repo/migrations` were generated with
`mix ash.codegen`.

## Bugs

| Id | Upstream repository | Summary | Test file | Status | Issue |
|---|---|---|---|---|---|
| ash/filter-combinator-shape | ash-project/ash | `and` / `or` with a value that is not a non-empty list or map raises `FunctionClauseError` | test/ash/filter_combinator_shape_test.exs | fixed in ash 3.33.6 | [#2937](https://github.com/ash-project/ash/issues/2937) |
| ash/is-nil-non-boolean-value | ash-project/ash | `is_nil` with a non-boolean is an unknown error | test/ash/is_nil_non_boolean_test.exs | fixed in ash 3.33.7 | [#2938](https://github.com/ash-project/ash/issues/2938) |
| ash/predicate-argument-types-unchecked | ash-project/ash | input filters do not check a predicate's argument types against the field, so range predicates on text (and `contains` on an integer) reach Postgres | test/ash/predicate_argument_types_unchecked_test.exs, plus a GraphQL introspection test | fixed in ash 3.33.6 | [#2939](https://github.com/ash-project/ash/issues/2939) |
| ash/invalid-page-options-unrendered | ash-project/ash | invalid `page` options are an unrendered `Spark.Options.ValidationError`; a non-list `page` raises | test/ash/invalid_page_options_test.exs | open | [#2940](https://github.com/ash-project/ash/issues/2940) |
| ash/sort-input-shape | ash-project/ash | `sort_input` with a non-list, non-string value raises (new) | test/ash/sort_input_shape_test.exs | fixed in ash 3.33.5 | [#2941](https://github.com/ash-project/ash/issues/2941) |
| ash_postgres/uncastable-filter-value-conversion | ash-project/ash_postgres | `Ecto.Query.CastError` is converted only where a rescue exists, and `Ecto.SubQueryError` is never unwrapped | test/ash_postgres/uncastable_filter_value_conversion_test.exs | open | [#855](https://github.com/ash-project/ash_postgres/issues/855) |
| ash_postgres/nul-byte-in-text | ash-project/ash_postgres | a NUL byte in text is an unconverted `Postgrex.Error` | test/ash_postgres/nul_byte_in_text_test.exs | open | [#854](https://github.com/ash-project/ash_postgres/issues/854) |
| ash_postgres/integer-past-64-bits-unconverted | ash-project/ash_postgres | an integer outside the `bigint` range is an unconverted `DBConnection.EncodeError` | test/ash_postgres/integer_past_64_bits_test.exs | open | [#853](https://github.com/ash-project/ash_postgres/issues/853) |
| ash_json_api/list-valued-query-params-crash | ash-project/ash_json_api | `include[]`, `fields[post][]`, `page[]` and `page[limit][]` raise | test/ash_json_api/list_valued_query_params_test.exs | fixed on main, unreleased | [#456](https://github.com/ash-project/ash_json_api/issues/456) |
| ash_graphql/null-boolean-filter-crash | ash-project/ash_graphql | `{and: null}`, `{or: null}`, `{not: null}`, `{not: []}` and a two-element `not` crash | test/ash_graphql/null_boolean_filter_test.exs | fixed in ash_graphql 1.12.0 | [#472](https://github.com/ash-project/ash_graphql/issues/472) |
| ash_graphql/negative-page-size-complexity | ash-project/ash_graphql | a negative page size crashes complexity analysis | test/ash_graphql/negative_page_size_complexity_test.exs | fixed in ash_graphql 1.12.0 | [#471](https://github.com/ash-project/ash_graphql/issues/471) |
| ash_graphql/unrendered-invalid-filter-value | ash-project/ash_graphql | `InvalidFilterValue` has no GraphQL rendering | test/ash_graphql/unrendered_invalid_filter_value_test.exs | open | [#473](https://github.com/ash-project/ash_graphql/issues/473) |
| ash_graphql/zero-page-size-unrendered | ash-project/ash_graphql | `first: 0` / `last: 0` is an unrendered error | test/ash_graphql/zero_page_size_test.exs | fixed in ash_graphql 1.12.0 | [#474](https://github.com/ash-project/ash_graphql/issues/474) |
| absinthe/lone-surrogate-escape-leaks-argument-error | absinthe-graphql/absinthe | `"\ud800"` and a surrogate pair escape leak Erlang's `ArgumentError` text | test/absinthe/lone_surrogate_escape_test.exs | open, fix proposed | [#1458](https://github.com/absinthe-graphql/absinthe/issues/1458) |
| ash_lua/returned-error-table-converted-only-at-top-level | ash-project/ash_lua | a returned error table keeps nested Lua tuples | test/ash_lua/nested_error_table_test.exs | fixed on main, unreleased | [#17](https://github.com/ash-project/ash_lua/issues/17) |
| ash_lua/host-exception-leaks-to-script | ash-project/ash_lua | a host exception before dispatch reaches the script verbatim | test/ash_lua/host_exception_leaks_to_script_test.exs | fixed on main, unreleased | [#16](https://github.com/ash-project/ash_lua/issues/16) |
| ash_lua/action-input-merged-under-query-controls | ash-project/ash_lua | action `input` is merged under the query controls | test/ash_lua/action_input_merged_under_controls_test.exs | fixed on main, unreleased | [#15](https://github.com/ash-project/ash_lua/issues/15) |
| ash_lua/unrendered-query-errors | ash-project/ash_lua | three Ash query errors render as `unknown_error` | test/ash_lua/unrendered_query_errors_test.exs | fixed on main, unreleased | [#18](https://github.com/ash-project/ash_lua/issues/18) |
| ash_ai/malformed-json-rpc-envelope | ash-project/ash_ai | malformed JSON-RPC envelopes crash the MCP server | test/ash_ai/malformed_json_rpc_envelope_test.exs | fixed on main, unreleased | [#229](https://github.com/ash-project/ash_ai/issues/229) |
| ash_ai/scalar-body-echoes-inspected-map | ash-project/ash_ai | a malformed body is echoed as an inspected Elixir term | test/ash_ai/scalar_body_echoes_inspected_map_test.exs | fixed in ash_ai 1.1.0 | [#230](https://github.com/ash-project/ash_ai/issues/230) |
| ecto/inspect-query-crashes-on-spark-regex-type-param | elixir-ecto/ecto | inspecting a query that holds an MFA-shaped tuple raises, so `Ecto.Query.CastError` cannot be raised | test/ecto/inspect_query_with_spark_regex_type_param_test.exs | closed as fixed in Elixir, unreleased | [#4793](https://github.com/elixir-ecto/ecto/issues/4793) |
| elixir/macro-to-string-mfa-tuple | elixir-lang/elixir | `Macro.to_string/1` crashes instead of inspecting an MFA-shaped tuple | test/elixir/macro_to_string_mfa_tuple_test.exs | fixed on main, unreleased | [#15903](https://github.com/elixir-lang/elixir/issues/15903) |

Two triggers from the original fuzzing run did not reproduce and have no test:
`sort[]=title` on JSON:API answers a clean 400, and an `Int` literal past 64
bits on GraphQL is rejected with a normal argument error. Under ash_ai,
`params._meta` and `params.clientInfo` as a string or list do not crash either
path.

Reclassified after review against the upstream sources: the 64-bit integer
bug is ash_postgres's, not Ash's (Ash's integer type is arbitrary precision
on purpose); the GraphQL filter types listing range predicates on every field
are a consequence of the Ash declarations and are kept as evidence under the
Ash report; `PATCH /posts/not-a-uuid` on JSON:API is a 500 caused by an
unconverted `Ecto.SubQueryError`, so it is part of the ash_postgres bug (case
6e); under ash_lua 0.2.2 `NoSuchField` is unrendered like the other two query
errors.

Every "Default branch: present" line below describes the state at filing: it
was checked by diffing the release the bug was found on against the
default-branch clone at the commit listed above. The "Status" line at the top
of each section is current as of 2026-09-21 and was checked by running the
suite against the releases named there.

## ash-project/ash

### ash/filter-combinator-shape

Status (2026-09-21): fixed in ash 3.33.6 by
[ash#2951](https://github.com/ash-project/ash/pull/2951); issue closed. All 8
bug tests pass on the pinned release.

Trigger: `Ash.Query.filter_input(Post, %{"and" => "x"})`, `%{"or" => ""}`,
`%{"or" => %{}}`, `%{"or" => []}`, `%{"or" => nil}` or `%{"and" => 5}`; on
JSON:API `GET /posts?filter[and]=x` or `filter[or]=`.

Observed:

```
** (FunctionClauseError) no function clause matching in Ash.Filter.parse_and_join/3
    (ash 3.33.3) lib/ash/filter/filter.ex:4942: Ash.Filter.parse_and_join("x", :and, ...)
```

The JSON:API router raises the same exception (a 500 in a server). By
contrast `Ash.Query.filter_input(Post, %{"not" => "x"})` puts an
`Ash.Error.Query.InvalidFilterValue` on the query (a control in the test).

Expected: `{:error, %Ash.Error.Invalid{}}` carrying an invalid filter error,
and a 400 on JSON:API.

Failure point: `Ash.Filter.parse_and_join/3`,
[lib/ash/filter/filter.ex#L4942-L4960](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/filter/filter.ex#L4942-L4960),
called unguarded from `add_expression_part/4` for `or` (L3050) and `and`
(L3058). The two clauses accept a non-empty list and a map; a string, nil, an
integer or an empty list matches neither, and an empty map matches the map
clause, reduces to `[]`, and then matches neither.

Default branch: present, unchanged at `a7a5105`.

Fix direction: a fallback clause returning `{:error, InvalidFilterValue}` for
any other value, and a decision for the empty list.

### ash/is-nil-non-boolean-value

Status (2026-09-21): fixed in ash 3.33.7 by commit
[`34e5e5e`](https://github.com/ash-project/ash/commit/34e5e5e), which wraps a
string parse error in `InvalidFilterValue`; both bug tests pass on the pinned
release. The issue was closed on 2026-09-21.

Trigger: `Ash.Query.filter_input(Post, %{"title" => %{"is_nil" => "maybe"}})`;
on JSON:API `GET /posts?filter[title][is_nil]=maybe`.

Observed:

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error: "Could not cast \"maybe\" as :boolean"}]}}
```

JSON:API answers 500 `something_went_wrong`.

Expected: `Ash.Error.Query.InvalidFilterValue` (an `Ash.Error.Invalid`), a 400.

Failure point: `Ash.Query.Operator.cast_one/2`,
[lib/ash/query/operator/operator.ex#L404-L427](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/operator/operator.ex#L404-L427),
returns `{:error, "Could not cast ..."}` with a bare string. `try_cast_with_ref/3`
([L239-L256](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/operator/operator.ex#L239-L256))
already builds an `InvalidFilterValue` when no type matches, but the truthy
`{:error, binary}` short-circuits `Enum.find_value/2` before that, and
`Ash.Error.to_ash_error/3` can only wrap a string as `UnknownError`.

Default branch: present, unchanged at `a7a5105`.

Fix direction: return `Ash.Error.Query.InvalidFilterValue.exception(value: value)`
from `cast_one/2`.

### ash/predicate-argument-types-unchecked

Status (2026-09-21): fixed in ash 3.33.6 by
[ash#2948](https://github.com/ash-project/ash/pull/2948); issue closed. All 7
bug tests pass on the pinned releases, and the GraphQL filter types no longer
list the range predicates on a text field, so that request is now rejected by
schema validation.

Trigger: `Ash.Query.filter_input(Post, %{"title" => %{"range_overlaps" => "x"}})`
on a `:string` attribute, also `range_adjacent` and `range_contains`, and
`filter_input(Post, %{"score" => %{"contains" => "x"}})` on an `:integer`
attribute; JSON:API `filter[title][range_overlaps]=x`; GraphQL
`listPosts(filter: {title: {rangeOverlaps: "x"}})`.

Observed:

```
** (Postgrex.Error) ERROR 42883 (undefined_function) operator does not exist: text && unknown
    query: SELECT ... FROM "posts" AS p0 WHERE ((p0."title"::text && $1))
```

(`-|-` for adjacent, `@>` for contains, `bigint ~~ unknown` for `contains` on
the integer.) Ash returns it as `Ash.Error.Unknown`; JSON:API answers 500;
GraphQL answers "Something went wrong".

Expected: an invalid filter error at parse time.

Failure point: when parsing an input filter, `Ash.Filter.get_predicate_function/3`
([lib/ash/filter/filter.ex#L5147-L5157](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/filter/filter.ex#L5147-L5157))
offers every non-private predicate function on every field, and
`Ash.Query.Function.try_cast_arguments/2`
([lib/ash/query/function/function.ex#L146-L190](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/function.ex#L146-L190))
passes a `%Ash.Query.Ref{}` through without comparing it to the declared
argument types, so the predicate reaches the data layer whatever the
declaration says. The three range predicates additionally declare their
argument types as `[:any, :same]`
([range_overlaps.ex#L19](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_overlaps.ex#L19),
[range_adjacent.ex#L18](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_adjacent.ex#L18);
`[:any, :any]` in
[range_contains.ex#L18](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/function/range_contains.ex#L18)).
That declaration is what AshGraphql uses to build its per-field predicate
lists, so it advertises the range predicates on every field, including text.
`test/ash_graphql/filter_type_range_predicates_test.exs` documents that as
evidence for this report (introspection of `PostFilterTitle` lists
`rangeOverlaps`, `rangeAdjacent`, `rangeContains`); ash_graphql renders the
declarations faithfully and is not reported.

Default branch: present, unchanged at `a7a5105` (all three range predicate
files are identical to 3.33.3).

Fix direction: compare the referenced attribute's type with the predicate's
declared argument types when parsing an input filter, and declare the range
predicates' first argument as `Ash.Type.Range` so the transports stop
advertising them on other fields.

### ash/invalid-page-options-unrendered

Status (2026-09-21): open; reproduces on ash 3.33.9.

Trigger: a read action with `pagination keyset?: true, offset?: true`;
`Ash.read(Post, page: [after: "x", offset: 1])`, and also `page: [limit: 0]`,
`[limit: -1]`, `[limit: "x"]` and `[limit: 1, offset: -1]`; JSON:API
`GET /posts?page[after]=x&page[offset]=1`. Separately, `Ash.read(Post, page: "x")`.

Observed:

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (Spark.Options.ValidationError) invalid value for :page option: unknown options [:offset], valid options are: [:before, :after, :limit, :filter, :count]"}]}}
```

(`invalid value for :limit option: expected positive integer, got: 0` and so
on for the others.) JSON:API answers 500. `page: "x"` raises
`FunctionClauseError` in `Access.get/3`. By contrast `page: [after: "x", limit: 1]`
returns `Ash.Error.Invalid` with `Ash.Error.Page.InvalidKeyset`, so sibling
page failures already have the invalid class.

Expected: an `Ash.Error.Invalid` describing the bad page options, a 400.

Failure point: `Ash.Page.page_opts/1`,
[lib/ash/page/page.ex#L16-L33](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/page/page.ex#L16-L33),
selects the keyset schema when `after` or `before` is present and returns the
`Spark.Options.ValidationError` message (and reads `page_opts[:after]` on
whatever value it gets, hence the raise for a string); `Ash.read/2` passes the
option validation failure to `Ash.Error.to_error_class/2`
([lib/ash.ex#L3149-L3150](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash.ex#L3149-L3150)),
which has no class for it. A zero page size on GraphQL fails the same way (see
`ash_graphql/zero-page-size-unrendered`).

Default branch: present, unchanged at `a7a5105`.

Fix direction: convert `:page` validation failures into an invalid-class error
before they reach `to_error_class/2`, and guard the shape of `page`.

### ash/sort-input-shape

Status (2026-09-21): fixed in ash 3.33.5 by
[ash#2947](https://github.com/ash-project/ash/pull/2947); issue closed. All 4
bug tests pass on the pinned release.

New: not in the original fuzzing run; found while reproducing the ash_lua
`sort = 5` case.

Trigger: `Ash.Query.sort_input(Post, 5)`, `sort_input(Post, %{})`,
`sort_input(Post, %{"title" => "asc"})`, or
`sort_input(Post, [%{"field" => "title"}])`.

Observed:

```
** (FunctionClauseError) no function clause matching in Ash.Sort.parse_input/3
```

and, for the list of maps, `no function clause matching in Ash.Resource.Info.attribute/2`.
By contrast, `Ash.Query.filter_input(Post, "title")` puts an
`InvalidFilterValue` on the query. A map is not a documented sort format; the
request is an invalid-sort error, not map support.

Expected: an invalid-class error on the query.

Failure point: `Ash.Sort.parse_input/3`, documented as "a utility for parsing
sorts provided from external input",
[lib/ash/sort/sort.ex#L94-L126](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/sort/sort.ex#L94-L126),
has clauses for a binary, an atom, a list and nil only, and the list clause
hands each element to `parse_sort/4`, whose catch-all reaches
`Ash.Resource.Info.attribute/2` (guarded `is_binary or is_atom`).
`Ash.Query.sort_input/3` already adds a returned `{:error, _}` to the query.

Default branch: present, unchanged at `a7a5105`.

Fix direction: a fallback clause returning an invalid sort error, and element
validation in the list clause.

## ash-project/ash_postgres

### ash_postgres/uncastable-filter-value-conversion

Status (2026-09-21): open; reproduces on ash_postgres 2.13.1, which is still the
newest release.

Ash does not cast filter values against the attribute type on purpose
(`Ash.Query.Operator.Eq` declares `types: [:any, :same]`), so an uncastable
value reaches the data layer and Ecto raises `Ecto.Query.CastError` while
planning the query. `AshPostgres.DataLayer.run_query/2` rescues that and
converts it to `Ash.Error.Query.InvalidFilterValue`. Three callbacks have no
rescue at all, and `handle_raised_error/4` does not unwrap an
`Ecto.SubQueryError` that carries the cast error, so the conversion happens
only where a rescue exists and the error is a bare cast error. All cases use a
UUID primary key and `id == "not-a-uuid"`.

| Case | Trigger | Observed |
|---|---|---|
| 6a | `Ash.count/2`, `Ash.exists/2`, `Ash.aggregate/3` | raises `Ecto.Query.CastError` |
| 6b | `query \|> Ash.Query.limit(1) \|> Ash.count()` | raises `Ecto.SubQueryError` wrapping the cast error |
| 6c | `Post \|> load(comments: Comment \|> filter(id == "not-a-uuid") \|> limit(1)) \|> Ash.read()` with two posts | raises `Ash.Error.Unknown` wrapping `Ecto.SubQueryError` |
| 6d | `filter_input(Post, %{comments: %{id: %{eq: "not-a-uuid"}}}) \|> Ash.read(page: [limit: 5])` | `{:error, %Ash.Error.Unknown{}}` wrapping `Ecto.SubQueryError` (the subquery comes from the pagination wrapper) |
| 6e | JSON:API `PATCH /posts/not-a-uuid` | 500; `update_query/4` returns `UnknownError` wrapping `Ecto.SubQueryError` |

Observed, 6a:

```
** (Ecto.Query.CastError) deps/ash_sql/lib/expr.ex:1960: value `"not-a-uuid"` in `where` cannot be cast to type #Ash.Type.UUID.EctoType<[]> in query: ...
```

Observed, 6c:

```
** (Ash.Error.Unknown)
* ** (Ecto.SubQueryError) the following exception happened when compiling a subquery.
    ** (Ecto.Query.CastError) ... value `"not-a-uuid"` in `where` cannot be cast ...
    (ash_postgres 2.13.1) lib/data_layer.ex:1148: AshPostgres.DataLayer.run_query_with_lateral_join/4
```

With one parent no lateral join is used and the error is clean (a control in
the test). `Ash.bulk_update/4` filtered by the bad id also converts cleanly
(another control), because without a limit the error is a bare `CastError`;
the JSON:API PATCH path goes through `update_query/4` with a subquery and does
not. The `Ash.DataLayer` behaviour declares `{:ok, _} | {:error, _}` for
`run_query`, `run_aggregate_query`, `run_aggregate_query_with_lateral_join`
and `run_query_with_lateral_join`
([lib/ash/data_layer/data_layer.ex#L179-L205](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/data_layer/data_layer.ex#L179-L205)),
so 6a to 6c also violate the callback contract.

Surfaces (effects of this bug, not separate ones): ash_lua
`blog.post.read({ filter = { id = "not-a-uuid" }, operation = "count" })` and
`"exists"` return a `lua_error` carrying the raw cast error text; GraphQL
`listPosts(first: 5) { results { comments(filter: {id: {eq: "not-a-uuid"}}, limit: 1) { id } } }`
and `listPosts(first: 5, filter: {comments: {id: {eq: "not-a-uuid"}}})` answer
"Something went wrong". GraphQL `listPosts(first: 1, filter: {id: {eq: "not-a-uuid"}}) { count }`
and JSON:API `page[count]=true` reach the count query only with
`config :ash, :disable_async?, true`; otherwise the page's own query fails
first (cleanly here, then unrendered by GraphQL, see
`ash_graphql/unrendered-invalid-filter-value`). The tests set the flag for
those two cases. The
three GraphQL tests assert that no cast error was logged rather than on the
rendered message, because a converted `InvalidFilterValue` is rendered as
"Something went wrong" too (`ash_graphql/unrendered-invalid-filter-value`).

Expected: `{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.InvalidFilterValue{}]}}`
everywhere, a 400 on JSON:API, a rendered error on GraphQL and Lua.

Failure points, all in
[lib/data_layer.ex](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex):
`run_query/2` rescues
([L890-L927](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L890-L927));
`run_aggregate_query/3`
([L977](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L977))
delegates to `AshSql.AggregateQuery.run_aggregate_query/4` with no rescue, and
`Ash.count/2` does not rescue either; `run_query_with_lateral_join/4`
([L1116](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L1116),
raise at L1148) has no rescue, nor does `run_aggregate_query_with_lateral_join/5`
([L996](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L996);
listed from reading the code, no test exercises it); `handle_raised_error/4`
converts a bare `Ecto.Query.CastError`
([L3289](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L3289))
but not an `Ecto.SubQueryError` whose `exception` is one, so `run_query/2`
(6d) and `update_query/4`
([L1840](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L1840),
rescue at L1959, 6e) fall through to the generic clause
([L3324](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L3324)).

Also observed: the working conversion passes the entire Ecto query as the
error's `context`, and `Ash.Error.Query.InvalidFilterValue.message/1`
interpolates it with `inspect/1`, so the message contains the query struct
including `__ash_bindings__` with the actor and tenant. Any surface that
renders `Exception.message/1` of that error exposes it (the ash_graphql and
ash_lua entries mention this).

Default branch: present; `lib/data_layer.ex` at `97ffea9` differs from 2.13.1
only by a new `view?` option, and ash_sql main `b5ae09a` is the 0.7.5 release
commit.

Fix direction: a rescue on the three callbacks like `run_query/2`'s, plus a
`handle_raised_error/4` clause for `%Ecto.SubQueryError{exception: %Ecto.Query.CastError{}}`.

### ash_postgres/nul-byte-in-text

Status (2026-09-21): open; reproduces on ash_postgres 2.13.1, which is still the
newest release.

Trigger: create or filter with a title containing a NUL byte (`"a" <> <<0>> <> "b"`):
`Ash.create/2`, `Ash.Query.filter/2`; JSON:API `POST /posts` with that title
and `GET /posts?filter[title]=a%00b`; GraphQL `createPost` with the value as a
variable and as a `\u0000` escape in the document; ash_lua
`blog.post.create({ input = { title = "a\0b" } })`.

Observed:

```
** (Postgrex.Error) ERROR 22021 (character_not_in_repertoire) invalid byte sequence for encoding "UTF8": 0x00
```

returned by the server and wrapped as `Ash.Error.Unknown`; JSON:API answers
500; GraphQL answers "something went wrong" in the mutation's `errors`; Lua
gets `unknown_error`. Invalid UTF-8 (`"a\255b"`, which only a Lua literal can
carry, since JSON transports refuse it on decoding) fails identically with
`0xff`.

Expected: an invalid-class error, as a constraint violation from the same
server already gets (`Ash.Error.Changes.InvalidAttribute` for a create,
`Ash.Error.Query.InvalidFilterValue` for a filter), a 400 on JSON:API. The
Postgres error names no column, so attributing it to the attribute is only
possible by inspecting the changeset.

Failure point: `handle_raised_error/4` in
[lib/data_layer.ex](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex)
has `Postgrex.Error` clauses for `lock_not_available` (L3195), `ash_error`
raises (L3218, L3241), bulk creates (L3261) and changeset inserts, updates and
deletes (L3279), plus a catch-all `Postgrex.Error` clause (L3298), all of which
end in `Ecto.Adapters.Postgres.Connection.to_constraints/2`. A `22021` produces
no constraints, so a create returns `Ash.Error.to_ash_error(%Postgrex.Error{})`
from L3269 (via `create/2` and `bulk_create/3`) and a read the same from the
catch-all clause, both unknown-class.

Ownership: Postgrex maintainers treat sanitising as the application's job
(elixir-ecto/postgrex#568, "Need way to sanitize string input", closed), and
only the data layer knows that this storage rejects NUL (ETS and Mnesia store
it), so the report goes to AshPostgres.

Default branch: present, unchanged at `97ffea9`.

Fix direction: map `%Postgrex.Error{postgres: %{code: :character_not_in_repertoire}}`
to an invalid-class error, attributing the field from the changeset when one
is present.

### ash_postgres/integer-past-64-bits-unconverted

Status (2026-09-21): open; reproduces on ash_postgres 2.13.1, which is still the
newest release.

Trigger: an integer attribute (`bigint`);
`Ash.Query.filter(Post, score == ^9_223_372_036_854_775_808)`, the same inside
`in`, `filter_input(Post, %{"score" => %{"in" => ["-99999999999999999999"]}})`,
and `Ash.create(Post, %{title: "big", score: 9_223_372_036_854_775_808})`;
JSON:API `filter[score][eq]=9223372036854775808`.

Observed:

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (DBConnection.EncodeError) Postgrex expected an integer in -9223372036854775808..9223372036854775807, got 9223372036854775808. ..."}]}}
```

JSON:API answers 500.

Expected: an invalid-class error: `Ash.Error.Query.InvalidFilterValue` on a
read, `Ash.Error.Changes.InvalidAttribute` on a create; a 400 on JSON:API.

Failure point: `Ash.Type.Integer.cast_input/2`
([lib/ash/type/integer.ex#L147-L149](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/type/integer.ex#L147-L149))
accepts any Elixir integer, which is correct for a type shared by data layers
without a 64-bit limit; only the data layer knows the column is `bigint`.
AshPostgres rescues the encode error in `run_query/2` (and the create path)
but `handle_raised_error/4` has no clause for `DBConnection.EncodeError` and
falls through to the generic clause
([lib/data_layer.ex#L3324](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex#L3324)),
next to the clause that already converts `Ecto.Query.CastError` (L3289).

Ownership: originally listed under Ash; after review it is filed with
ash_postgres for the reasons above.

Default branch: present, unchanged at `97ffea9`.

Fix direction: a `handle_raised_error/4` clause for `DBConnection.EncodeError`
mapping to `InvalidFilterValue` in a query context and `InvalidAttribute` in a
changeset context.

## ash-project/ash_json_api

### ash_json_api/list-valued-query-params-crash

Status (2026-09-22): fixed on main by our
[ash_json_api#457](https://github.com/ash-project/ash_json_api/pull/457) (commit
`7c7d25f`, merged 2026-09-22); issue closed. Not released: reproduces on
ash_json_api 1.7.1, which is still the newest release. All four bug tests pass
against main.

Trigger: `GET /posts?include[]=comments`, `GET /posts?fields[post][]=title`,
`GET /posts?page[]=1` and `GET /posts?page[limit][]=1`. The query string
decodes these to lists in `Plug.Conn.Query`, the same path a Phoenix endpoint
uses.

Observed:

```
** (FunctionClauseError) no function clause matching in String.split/3
    (elixir 1.20.1) lib/string.ex:518: String.split(["comments"], ",", [])
    (ash_json_api 1.7.1) lib/ash_json_api/includes/parser.ex:14: AshJsonApi.Includes.Parser.parse_and_validate_includes/2
```

`fields[post][]=title`: the same from `lib/ash_json_api/request.ex:798:
AshJsonApi.Request.add_fields/4`. `page[]=1`: `BadMapError` from
`lib/ash_json_api/controllers/helpers.ex:1013`. `page[limit][]=1`:
`FunctionClauseError` in `Integer.parse/2`. Each escapes `AshJsonApi.Router`
unrescued, a 500 in any Plug or Phoenix deployment. `sort[]=title` answers 400
with `invalid_sort` and `invalid_query` errors, the latter from the route's
own hrefSchema, which types `include` as a string too; includes and page
parameters are read before that schema is validated. `fields[]=title` is
silently ignored (200).

Expected: a 400 with the existing `invalid_includes`, `invalid_field` or
`invalid_pagination` error.

Failure points: `AshJsonApi.Includes.Parser.parse_and_validate_includes/2`,
[lib/ash_json_api/includes/parser.ex#L10-L15](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/includes/parser.ex#L10-L15),
called from `Request.from/7` at
[request.ex#L80](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/request.ex#L80)
before `validate_href_schema/1` runs; `AshJsonApi.Request.add_fields/4`,
[request.ex#L793-L798](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/request.ex#L793-L798);
`AshJsonApi.Controllers.Helpers.add_pagination_parameter/3`,
[controllers/helpers.ex#L1013](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/controllers/helpers.ex#L1013).
The neighbouring `parse_sort/1` and `parse_filter/1` have catch-all clauses
that return `InvalidSort` / `InvalidFilter`.

Default branch: present, unchanged at `fe58c33`.

Fix direction: guard on `is_binary/1` (or `is_map/1` for `page`) and return
the existing errors for other shapes.

## ash-project/ash_graphql

The schema is `use Absinthe.Schema` plus `use AshGraphql, domains: [Repro.Blog]`,
served by `Absinthe.Plug` forwarded from a `Plug.Router` with
`analyze_complexity: true` (the configuration in ash_graphql's own
documentation) and no `max_complexity`. The router does not add
`AshGraphql.Plug`, which only copies actor, tenant and context from the conn;
with no policies that changes nothing here.

### ash_graphql/null-boolean-filter-crash

Status (2026-09-21): fixed in ash_graphql 1.12.0 by
[ash_graphql#475](https://github.com/ash-project/ash_graphql/pull/475); issue
closed. All 5 bug tests pass on the pinned release.

Trigger: `listPosts(filter: {and: null})`, `{or: null}`, `{not: null}`,
`{not: []}`, and `{not: [{title: {eq: "x"}}, {score: {eq: 9}}]}` (any `not`
list that is not exactly one element). The generated schema types `and`, `or`
and `not` as `[PostFilterInput!]`, a nullable list, so all of these pass
Absinthe validation and reach the resolver. `{and: []}` and `{or: []}` are
handled.

Observed: `"Something went wrong. Unique error id: ..."` with a logged

```
** (FunctionClauseError) no function clause matching in AshGraphql.Graphql.FilterHandlers.process_boolean_filter/5
    (ash_graphql 1.11.0) lib/graphql/filter_handlers.ex:172
```

Expected: the combinator is applied (or ignored when empty), or a rendered
invalid filter error.

Failure point: `process_boolean_filter/5`,
[lib/graphql/filter_handlers.ex#L172-L181](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/filter_handlers.ex#L172-L181),
has clauses for `:not` with a one-element list or a map and for `:and` / `:or`
with a list.

Default branch: present, unchanged at `fd31401`.

Fix direction: clauses for `nil`, `[]` and a multi-element `not` list.

### ash_graphql/negative-page-size-complexity

Status (2026-09-21): fixed in ash_graphql 1.12.0 by
[ash_graphql#476](https://github.com/ash-project/ash_graphql/pull/476); issue
closed. All 3 bug tests pass on the pinned release.

Trigger: with `analyze_complexity: true` on `Absinthe.Plug`,
`listPosts(first: -1)`, `listPosts(last: -1)`, or a relationship field
`comments(limit: -1)`.

Observed: the request raises before any resolver runs, an uncaught 500 with no
GraphQL error body (`Absinthe.AnalysisError` has no `Plug.Exception`
implementation and `Absinthe.Plug` does not rescue):

```
** (Absinthe.AnalysisError) Invalid value returned from complexity analyzer.
Analyzing field: listPosts ... Got value: -2
The complexity value must be a non negative integer.
```

Setting `max_complexity` does not change this; the raise is in Absinthe's
analysis phase, before the limit is read. With `analyze_complexity: false`,
`listPosts(first: -1)` is the same unrendered `Spark.Options.ValidationError`
as `first: 0` (see `ash_graphql/zero-page-size-unrendered`), while
`comments(limit: -1)` returns an empty list.

Expected: a GraphQL error for the invalid page size, and a complexity value
that is never negative.

Failure point: `AshGraphql.Graphql.Resolver.query_complexity/3`,
[lib/graphql/resolver.ex#L3498-L3538](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L3498-L3538),
multiplies the child complexity by `limit`, `first` or `last` with no floor.
Absinthe documents the return as a non-negative integer and raises otherwise
([lib/absinthe/type/field.ex#L176](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/type/field.ex#L176),
[lib/absinthe/phase/document/complexity/analysis.ex#L88-L95](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/phase/document/complexity/analysis.ex#L88-L95)),
so the crash is ash_graphql's. The `first` / `last` clauses were added in
1.11.0 (CVE-2026-81636) together with `is_integer` guards for a null limit.

Default branch: present, unchanged at `fd31401`.

Fix direction: floor the multiplication at 0 in `query_complexity/3` and
reject `first` / `last` below 1 in `validate_keyset_opts/3`; the floor alone
turns the 500 into the unrendered error above.

### ash_graphql/unrendered-invalid-filter-value

Status (2026-09-21): open; reproduces on ash_graphql 1.12.0.

Trigger: `getPost(id: "not-a-uuid")` or
`listPosts(filter: {id: {eq: "not-a-uuid"}})`.

Observed: `{"errors":[{"message":"Something went wrong. Unique error id: ..."}]}`
with a logged `AshGraphql.Error not implemented for error: ** (Ash.Error.Query.InvalidFilterValue)`.
The query path returns only `message`, with no `code`, `fields` or `vars`.

Expected: an error with code `invalid_filter_value`.

Failure point: `lib/error.ex` has no `AshGraphql.Error` implementation for
`Ash.Error.Query.InvalidFilterValue`
([lib/error.ex](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/error.ex)).
For a query, `AshGraphql.Graphql.Resolver.to_resolution/3`
([lib/graphql/resolver.ex#L3616-L3660](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L3616-L3660))
logs it and emits the bare message; for a mutation, `AshGraphql.Errors.to_errors/6`
([lib/graphql/errors.ex#L28-L78](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/errors.ex#L28-L78))
does the same with a lowercase message.

Default branch: present, unchanged at `fd31401`.

Fix direction: add the implementation with a fixed message; do not use
`Exception.message/1`, which interpolates the Ecto query on ash_postgres.

### ash_graphql/zero-page-size-unrendered

Status (2026-09-21): fixed in ash_graphql 1.12.0 by
[ash_graphql#476](https://github.com/ash-project/ash_graphql/pull/476); issue
closed. Both bug tests pass on the pinned release.

Trigger: `listPosts(first: 0)`, or `listPosts(last: 0, before: cursor)` with a
valid keyset cursor (`last` without `before` is rejected cleanly).

Observed: `"Something went wrong. Unique error id: ..."` with a logged

```
** (Ash.Error.Unknown)
* ** (Spark.Options.ValidationError) invalid value for :page option: invalid value for :limit option: expected positive integer, got: 0
```

A relationship field's `comments(limit: 0)` legitimately returns an empty list
(a control in the test).

Expected: a rendered error, or an empty page for 0 (the Relay connection spec
treats `first: 0` as an empty connection).

Failure point: two defects stack. `validate_keyset_opts/3` maps `first` and
`last` straight onto the page `limit`
([lib/graphql/resolver.ex#L1345-L1349](https://github.com/ash-project/ash_graphql/blob/v1.11.0/lib/graphql/resolver.ex#L1345-L1349))
although it already rejects four other invalid combinations with a clean
`InvalidQuery` (L1322-L1356); and Ash surfaces the resulting
`Spark.Options.ValidationError` as `Ash.Error.Unknown`
(`ash/invalid-page-options-unrendered`). The ash_graphql half is this report;
`ash_graphql/negative-page-size-complexity` shares it.

Default branch: present, unchanged at `fd31401`.

Fix direction: reject `first` / `last` below 1 with an `InvalidQuery` before
building the page options.

## absinthe-graphql/absinthe

### absinthe/lone-surrogate-escape-leaks-argument-error

Status (2026-09-21): open; reproduces on absinthe 1.12.0. A fix is proposed in
[absinthe#1460](https://github.com/absinthe-graphql/absinthe/pull/1460); both
bug tests pass against its head `2067bdb`.

Trigger: any document with a string literal containing an escaped lone
surrogate, for example `{ echo(value: "a\\ud800b") }`, or an escaped surrogate
pair, `{ echo(value: "\\ud83d\\ude00") }` (the fixed-width spelling of U+1F600
that the current spec keeps for compatibility). The test uses its own
one-field schema and `Absinthe.run/3`; no Ash involved, and the draft carries a
`Mix.install` script that needs no database.

Observed, for both documents:

```
{:ok, %{errors: [%{message: "An unknown error occurred during parsing: errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n"}]}}
```

The error carries no `locations`. The text after the colon is OTP's
`error_info` formatting (stdlib 8.0.1 here) and may read differently on older
OTP. `\u{1F600}`, `\uZZZZ` and `\u12` pass through as literal text.

Expected: a syntax error with a location for the lone surrogate, and U+1F600
for the pair, with no exception text in either case.

Failure point: `unescape_unicode/5` converts each `\uXXXX` escape with
`:unicode.characters_to_binary/1` and ignores the return value
([lib/absinthe/lexer.ex#L367-L372](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/lexer.ex#L367-L372)).
For a surrogate that call returns `{:error, <<>>, [0xD800]}` instead of a
binary, so `Absinthe.Lexer.tokenize/1` succeeds and hands the parser a
malformed token, `{:string_value, {1, 15}, [34, 97, {:error, "", [55296]}, 98, 34]}`.
The `ArgumentError` is raised by the parser, in `extract_quoted_string_token/1`
([src/absinthe_parser.yrl#L422-L423](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/src/absinthe_parser.yrl#L422-L423)),
which calls `unicode:characters_to_binary/1` on that list. `Absinthe.Phase.Parse`
rescues it
([lib/absinthe/phase/parse.ex#L86-L88](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/phase/parse.ex#L86-L88))
and renders it with `Exception.message/1`
([L116-L127](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/phase/parse.ex#L116-L127)).
The lexer implements only `EscapedUnicode :: /[0-9A-Fa-f]{4}/`
([lexer.ex#L158-L161](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/lexer.ex#L158-L161))
and converts each escape independently, so a pair is never combined.

An `Int` literal past 64 bits (`first: 99999999999999999999`) is rejected by
`Int` scalar validation with a normal argument error (the lexer accepts the
arbitrary-precision literal) and is not reported.

Default branch: unchanged at `1372ceb`, which is the 1.12.0 release commit.

Fix direction: range-check the code point in `unescape_unicode/5` (or check
the `:unicode.characters_to_binary/1` return) and return a lexer error so the
normal `Parsing failed at ...` path with a location applies; combine surrogate
pairs. The `Exception.message/1` suffix in `Phase.Parse` is a last-resort
diagnostic and need not change.

## ash-project/ash_lua

All Lua cases call `AshLua.Eval.run/2` against an eval resource
(`Repro.LuaSurface`) exposing `Repro.Post`'s `read`, `create` and a custom
`search` read action. All four also reproduce with
`AshLua.Eval.run(script, otp_app: :repro)`, so they are not specific to the
`eval_actions ... resource` form. The tests use a helper (`lua_error/1`) that
re-converts nested Lua tables, so the last three can be asserted independently
of the first bug.

### ash_lua/returned-error-table-converted-only-at-top-level

Status (2026-09-21): fixed on main by commit
[`895745e`](https://github.com/ash-project/ash_lua/commit/895745e); issue
closed. Not released: reproduces on ash_lua 0.2.2, which is still the newest
release.

Trigger: `local r, err = blog.post.read({ filter = { title = { nope = "x" } } }) return r, err`
(returning `(result, err)` is the documented calling convention).

Observed: the run result's `error` is
`%{"class" => "invalid", "errors" => [{1, [{"code", "unknown_error"}, {"fields", []}, ...]}]}`;
nested tables are lists of `{key, value}` tuples, and `Jason.encode/1` of the
result returns `{:error, %Protocol.UndefinedError{protocol: Jason.Encoder, value: {1, [...]}}}`.
A returned result table is converted at every depth (a control), so only the
error slot is affected. ash_ai's MCP server rescues a `Jason.encode!` failure
into the generic tool reply "unexpected error occurred"
(`lib/ash_ai/mcp/server.ex#L1048-L1050`, not exercised here).

Expected: `"errors"` is a list of maps and the result is JSON-encodable.

Failure point: `normalize_error/1` in `split_lua_return/1` uses `Map.new/1`,
top level only
([lib/ash_lua/eval.ex#L231-L239](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/eval.ex#L231-L239)),
while the raise path decodes recursively with `AshLua.Encoder.decode_input/1`
(`extract_structured_error/1`, L200-L227) and results go through the recursive
`AshLua.Encoder.encode_result/1`
([lib/ash_lua/encoder.ex#L152](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/encoder.ex#L152)).

Default branch: present, unchanged at `2fb5f49` (the 0.2.2 release commit).

Fix direction: decode the error table recursively, as the raise path does.

### ash_lua/host-exception-leaks-to-script

Status (2026-09-21): fixed on main by commit
[`895745e`](https://github.com/ash-project/ash_lua/commit/895745e); issue
closed; not released. Both triggers used here stopped raising once Ash fixed the
crashes underneath them (the sort case in ash 3.33.5, the filter case in ash
3.33.6), so the two bug tests pass on the pinned releases and are tagged
`fixed_in:` with those Ash versions.

Trigger: `blog.post.read({ filter = { ["or"] = {} } })` and
`blog.post.read({ sort = 5 })`.

Observed: the call does not return `(nil, err)`; the whole script aborts (its
`print_output` is lost) and the run result's error is a `lua_error` leaf with
empty `vars` and no top-level `class`:

```
%{"code" => "lua_error", "message" => "Lua runtime error: no function clause matching in Ash.Filter.parse_and_join/3", ...}
```

(`Ash.Sort.parse_input/3` for the sort). The same happens for a raise from the
data layer, for example `Ecto.Query.CastError` on `operation = "count"` with an
uncastable id (see the ash_postgres entry).

Expected: a structured invalid-input error returned as `(nil, err)`, without
exception text. `AshLua.Runtime`'s own contract says action callables always
return `(result, nil)` or `(nil, err_table)`.

Failure point: the runtime calls `Ash.Query.filter_input/2` and
`Ash.Query.sort_input/2` while building the query
([lib/ash_lua/runtime.ex#L970-L974](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L970-L974));
those raise (see `ash/filter-combinator-shape` and `ash/sort-input-shape`),
the exception escapes the Lua callback as a `Lua.RuntimeException`, and
`AshLua.Eval` renders it with `Exception.message/1`
([lib/ash_lua/eval.ex#L255-L258](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/eval.ex#L255-L258)).
ash_lua has no hook between decoding a call's arguments and dispatching it, so
an application cannot validate them first.

Default branch: present, unchanged at `2fb5f49`.

Fix direction: rescue around query building and dispatch and return a
structured error as `(nil, err)`; never put host exception text in a
`lua_error`.

### ash_lua/action-input-merged-under-query-controls

Status (2026-09-21): fixed on main by commit
[`506085c`](https://github.com/ash-project/ash_lua/commit/506085c); issue
closed. Not released: reproduces on ash_lua 0.2.2, which is still the newest
release.

Trigger: a read action with an argument named `limit`;
`blog.post.search({ input = { limit = 1 } })` with three posts, and
`blog.post.search({ input = { limit = 2^63 } })` (a Lua float); also the
control key `blog.post.read({ limit = "x" })`.

Observed: `input.limit = 1` returns one post with no error, so the action
argument became the query limit and never reached the action. The generated
documentation for the action (`AshLua.Eval.docs/2`) lists both `input.limit`
and the control key `limit`. `2^63` gives `unknown_error` with a logged
`AshLua.Error not implemented for error: ** (Ash.Error.Query.InvalidLimit) 9.223372036854776e18 is not a valid limit`;
`limit = "x"` is the same unrendered `InvalidLimit`. Those two are a separate
gap of the same kind as `ash_lua/unrendered-query-errors`.

Expected: `input.limit` reaches the action as an argument, or the name
collision is rejected at compile time as a renamed argument onto a reserved
key already is (`AshLua.Resource.Verifiers.VerifyNames`, `verify_names.ex`
L154); an invalid limit is a rendered error.

Failure point: `build_action_callback/3` merges the action input under the
controls (`input = Map.merge(action_input, controls)`,
[lib/ash_lua/runtime.ex#L586](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L586))
and the dispatch pops `page`, `filter`, `sort`, `limit` and `offset` from the
merged map
([L754-L759](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L754-L759)
and [L873-L877](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/runtime.ex#L873-L877)).
`Ash.Error.Query.InvalidLimit` has no `AshLua.Error` implementation.

Default branch: present, unchanged at `2fb5f49`.

Fix direction: carry action input and query controls separately, or reject the
collision in the verifier; add a rendering for `InvalidLimit`.

### ash_lua/unrendered-query-errors

Status (2026-09-21): fixed on main by commit
[`895745e`](https://github.com/ash-project/ash_lua/commit/895745e); issue
closed. Not released: reproduces on ash_lua 0.2.2, which is still the newest
release.

Trigger: `blog.post.read({ filter = { id = "not-a-uuid" } })`
(`InvalidFilterValue`), `{ filter = { title = { nope = "x" } } }`
(`NoSuchFilterPredicate`), `{ filter = { nope = "x" } }` (`NoSuchField`).

Observed: `code = "unknown_error"` with a uuid and a logged
`AshLua.Error not implemented for error: ** (Ash.Error.Query.NoSuchField) No such field nope for resource Repro.Post`.
A `fields` mistake, by contrast, renders as `unknown_field` with the field
name (a control). The original fuzzing report expected `NoSuchField` to be
rendered; on 0.2.2 it is not.

Expected: structured errors naming the field or predicate.

Failure point: `lib/ash_lua/error.ex` has 14 `AshLua.Error` implementations
(plus two compiled only when `ash_authentication` is present) and none for
these three
([lib/ash_lua/error.ex](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/error.ex));
`render_error/1` falls back to `log_unknown_error/1`
([lib/ash_lua/encoder.ex#L493-L501](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/encoder.ex#L493-L501),
[L532-L554](https://github.com/ash-project/ash_lua/blob/v0.2.2/lib/ash_lua/encoder.ex#L532-L554)).

Default branch: present, unchanged at `2fb5f49`.

Fix direction: add the three implementations with fixed messages (not
`Exception.message/1`: `InvalidFilterValue`'s `:context` holds the full Ecto
query on ash_postgres, and the other two interpolate `inspect(resource)`).

## ash-project/ash_ai

The MCP router is mounted with one tool (`tools: [:read_posts]`). The tests
call `AshAi.Mcp.Router.call/2` directly with `Plug.Test`, as ash_ai's own MCP
tests do, rather than forwarding from a parent `Plug.Router`, because
`Plug.Router.forward/2` adds a `glob` path parameter that the server would
echo. The router installs its own `Plug.Parsers`, so the `_json` wrapping
below is what production sees.

Requests without an `MCP-Protocol-Version` header and without `_meta` take the
initialize-based `2025-06-18` / `2025-03-26` path (a header naming an earlier
revision selects it too, and an `initialize` request without `_meta` always
does); requests with the header `MCP-Protocol-Version: 2026-07-28` and
`_meta` in `params` take the per-request `2026-07-28` path (a `_meta` protocol
version with no header selects it as well and then answers `-32020`).

### ash_ai/malformed-json-rpc-envelope

Status (2026-09-22): fixed on main by our
[ash_ai#238](https://github.com/ash-project/ash_ai/pull/238) (commit `e0545a2`,
merged 2026-09-22); issue closed. Not released: reproduces on ash_ai 1.1.0,
which is still the newest release. All eleven bug tests pass against main.

| Shape | initialize-based path | 2026-07-28 path |
|---|---|---|
| batch array, `[]` or `[{...}]` | `FunctionClauseError` in `AshAi.Mcp.Server.parse_json_rpc/1` | clean `-32600` |
| `params` as a string, on `tools/call` or `initialize` (methods that ignore `params`, such as `tools/list`, answer 200) | `FunctionClauseError` in `Access.get/3` | raises, for every method with an id |
| `params` as a list, same methods | `ArgumentError` from `Access` ("supports only keyword lists") | raises, for every method with an id |
| `params.arguments` as a string / list | `Access.get/3` / `ArgumentError` | same |
| `initialize` with `params.capabilities` as a string / list | `FunctionClauseError` in `Access.get/3` / `ArgumentError` | not applicable (`initialize` removed) |

`params._meta` as a string or list is ignored on the initialize-based path and
rejected with `-32602` on the 2026-07-28 path; `params.clientInfo` is never
read on either path (client identity lives in `_meta` on the new path, where a
malformed value is rejected with `-32602`). Neither crashes.

Observed, batch: `** (FunctionClauseError) no function clause matching in AshAi.Mcp.Server.parse_json_rpc/1`
raised through the router (a 500 with no JSON-RPC body; the router has no
error handler).

Expected: a JSON-RPC error (`-32600` or `-32602`) with the request's id where
it has one.

Failure points in
[lib/ash_ai/mcp/server.ex](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex):
`unwrap_json_params/1` turns a `_json` list back into a list
([L111](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L111))
but `parse_json_rpc/1` has clauses for a binary and a map only
([L1336-L1345](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L1336-L1345)),
so the batch branch of `process_request/3` (L650-L664) is unreachable through
the router; `execute_tool_call/3` reads `params["name"]`
([L974](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L974))
for a scalar `params`; a scalar `arguments` passes `params["arguments"] || %{}`
(L975) and raises one level down in `AshAi.Tool.Execution.run/4`,
`arguments["input"]`
([lib/ash_ai/tool/execution.ex#L56](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/tool/execution.ex#L56)),
before the `try/rescue` at L79, although a non-object `input` inside
`arguments` is already rejected with a helpful message by
`validate_input_shape/1` (L475-L481); `initialize` reads
`params["capabilities"] || %{}` (L693) without raising, and the raise is in
`ui_capable?/1`
([L880](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L880)),
reached from `maybe_add_ui_capability/3` (L858-L859) even with no UI resources
configured; `validate_request_meta/1` uses `get_in(message, ["params", "_meta"])`
([L206](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L206))
first thing on the 2026-07-28 path.

Default branch: present; `lib/ash_ai/mcp/server.ex` and `router.ex` are
identical at `158d5e9`, and `tool/execution.ex` differs only after the raise
site.

Fix direction: validate the envelope shape before dispatch on both paths:
`params`, `arguments`, `capabilities` must be objects (`-32602`), and the
initialize-based path must either support batches or answer `-32600`.

### ash_ai/scalar-body-echoes-inspected-map

Status (2026-09-21): fixed in ash_ai 1.1.0 by
[ash_ai#234](https://github.com/ash-project/ash_ai/pull/234); issue closed. Both
bug tests pass on the pinned release.

Trigger: the request body `5` (also `"hi"`, `true`, `null`, or any JSON
object without a `method` key), on either path.

Observed: `{"error":{"code":-32600,"message":"Invalid Request Got: %{\"_json\" => 5}"}}`
(HTTP 200 on the initialize-based path, 400 on the 2026-07-28 path). The
`_json` key is `Plug.Parsers`' representation of a non-object body, so the
message describes something the client did not send. An object without
`method` is echoed with up to 50 of its own keys and values.

Expected: a fixed message with no inspected Elixir terms.

Failure point: the catch-all clauses interpolate `inspect(other)`:
[L200](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L200)
(2026-07-28) and
[L836](https://github.com/ash-project/ash_ai/blob/v1.0.3/lib/ash_ai/mcp/server.ex#L836)
(initialize-based).

Default branch: present, unchanged at `158d5e9`.

Fix direction: "Invalid Request: expected a JSON-RPC request object".

## elixir-ecto/ecto

### ecto/inspect-query-crashes-on-spark-regex-type-param

Status (2026-09-21): closed upstream as fixed by the Elixir change below; Ecto
itself is unchanged. Reproduces until an Elixir release carries that change.

`Inspect.Ecto.Query` renders expressions, type parameters and interpolated
values through `Macro.to_string/1`
([lib/ecto/query/inspect.ex#L260-L267](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/query/inspect.ex#L260-L267)
and [L307-L318](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/query/inspect.ex#L307-L318)).
A three-tuple such as `{Foo, :cache, ["a", []]}` anywhere in that expression
makes `Macro.to_string/1` raise (see the Elixir entry below). `Ecto.QueryError`
and `Ecto.SubQueryError` interpolate `Inspect.Ecto.Query.to_string(query)`
into their own messages
([lib/ecto/exceptions.ex#L36](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/exceptions.ex#L36),
[L78](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/exceptions.ex#L78)),
and `Ecto.Query.CastError` inherits the crash because
`Ecto.Query.Planner.cast_param/6` builds an `Ecto.QueryError` just to obtain
its message
([lib/ecto/query/planner.ex#L1153-L1161](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/query/planner.ex#L1153-L1161)).

How it was hit: Spark stores a `match:` regex constraint as
`{Spark.Regex, :cache, [source, opts]}`
([lib/spark/options/options.ex#L1152-L1168](https://github.com/ash-project/spark/blob/v2.7.3/lib/spark/options/options.ex#L1152-L1168),
used by `Ash.Type.String`'s `match` constraint), and AshPostgres copies a
type's constraints into the Ecto type parameters
([lib/sql_implementation.ex#L488-L512](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/sql_implementation.ex#L488-L512)).
`Ecto.ParameterizedType` documents params as `term()` ("idiomatically a map"),
so no contract is violated.

Levels, each in the test file:

(a) Pure Ecto, no repo needed: a query with
`type(^"abc", {:parameterized, {RegexParamType, [match: {Spark.Regex, :cache, ["^[a-z]+$", []]}]}})`
cannot be inspected (`#Inspect.Error<got FunctionClauseError ... Access.get/3>`),
and a cast failure on the same query raises `FunctionClauseError` instead of
`Ecto.Query.CastError`. With `[match: "x"]` both work (a control). Params held
in a map rather than a keyword list do not reproduce, because
`Code.Normalizer` treats map values as literals.

(b) Pure Ecto with a built-in type and no parameterized type:
`Repo.all(from p in "posts", where: p.title == type(^{Foo, :cache, ["a", []]}, :string))`
raises `FunctionClauseError` where `^{1, 2, 3}` raises a clean
`Ecto.Query.CastError` (a control). Interpolated values are arbitrary user
terms, and the clause that splices them already special-cases one non-AST
hazard (a charlist head, L311-L312).

(c) Smallest Ash resource: `Repro.Post` has
`calculate :title_slug, :string, expr(title)` with `constraints match: ~r/^[a-z]+$/`.
An attribute with the same constraint is not enough, because AshSql does not
cast a plain string comparison; the calculation's SQL cast carries the
constraints. `Post |> Ash.Query.load(:title_slug) |> Ash.Query.filter(id == "not-a-uuid") |> Ash.read()`
returns

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error: "** (FunctionClauseError) no function clause matching in Access.get/3"}]}}
```

instead of `InvalidFilterValue`; the same read without the load converts
cleanly (a control). In the application this was found in, an embedded map
type with `fields` constraints carrying `match:` patterns, loaded through a
calculation, turned every malformed-id filter on that resource into an
internal error.

Expected: `inspect/1` succeeds and `Ecto.Query.CastError` is raised normally.

Which report: Ecto, and it stands on its own (it does not depend on the
Elixir fix, which would leave other callers unaffected but is independently
worth having). Rendering type parameters with `inspect/1` alone would not
cover the interpolated-value path; rescuing in `Inspect.Ecto.Query`, or
sanitising every spliced term, covers both. Wrapping such a term in
`{:__block__, [], [term]}` does not help: `Code.Normalizer.do_normalize/2`
unwraps and recurses into it. Spark's tuple is a deliberate design for OTP 28,
so no Spark report; AshSql could strip non-type constraints such as `match`
before building the Ecto type, which would avoid the trigger but not the
underlying fragility.

Default branch: present; `lib/ecto/query/inspect.ex` on master `24f914a`
differs from 3.14.2 only in an unrelated clause, and `exceptions.ex` is
identical.

## elixir-lang/elixir

### elixir/macro-to-string-mfa-tuple

Status (2026-09-21): fixed on main by commit
[`2f09141`](https://github.com/elixir-lang/elixir/commit/2f091416b42cc4b2fbc9cdaf706ca75dd7af7f5a);
issue closed. Not on the v1.20 branch and not in a release (the newest tag is
v1.20.4); reproduces on Elixir 1.20.1.

Trigger: `Macro.to_string({Foo, :cache, ["a", []]})`.

Observed:

```
** (FunctionClauseError) no function clause matching in Access.get/3
    (elixir 1.20.1) lib/access.ex: Access.get(:cache, :line, nil)
    (elixir 1.20.1) lib/code/normalizer.ex:586: Code.Normalizer.patch_meta_line/2
    (elixir 1.20.1) lib/code/normalizer.ex:323: Code.Normalizer.normalize_call/2
```

Reproduced on Elixir 1.18.4, 1.19.5, 1.20.1 and 1.20.2, so it is not a 1.20
regression. `Macro.to_string({1, 2, 3})`, `{"a", "b", "c"}` and
`{Foo, :cache, "x"}` render as inspected terms (a control); only a three-tuple
with an atom in the metadata position and a list or atom in the third position
crashes.

Expected: the node is inspected, as `{Foo, :cache, ["a", []]}`. The
`Macro.to_string/1` docs say that invalid nodes are inspected to aid
debugging, and Elixir has fixed the same class before (for example
elixir-lang/elixir#12922 and #13895, each by adding a guard so the node falls
through to `inspect/1`).

Failure point: `Code.Normalizer` matches any three-tuple with list arguments
as a call
([lib/elixir/lib/code/normalizer.ex#L228-L230](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L228-L230))
and `normalize_call/2` passes the second element to `patch_meta_line/2`, which
reads `meta[:line]` on the atom `:cache`
([L322-L323](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L322-L323),
[L585-L586](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L585-L586)).
A guard on the normalizer alone is not enough; `Code.Formatter` reads the
metadata too and needs the same `is_list(meta)` guards.

Default branch: present at `39164ec` (call clause at L231, `patch_meta_line/2`
at L601-L602).

Fix direction: `is_list(meta)` guards on the call clauses in `Code.Normalizer`
and `Code.Formatter`, so the tuple falls through to `inspect/1`.

## Layout

```
lib/repro/            domain, resources, routers, GraphQL schema, Lua surface
lib/mix/tasks/        mix repros.check
lib/repro/check_formatter.ex
test/<upstream>/      one file per bug
test/support/case.ex  sandbox setup and the JSON:API, GraphQL, Lua and MCP drivers
bug_reports/          one draft bug report per bug, plus a summary per upstream repository
priv/repo/migrations  generated with mix ash.codegen
```

No license file is included; the choice is left to the repository owner.
