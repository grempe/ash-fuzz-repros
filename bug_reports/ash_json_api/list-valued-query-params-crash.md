# include[], fields[type][], page[] and page[limit][] crash the request parser

Versions: ash_json_api 1.7.1, ash 3.33.3, ash_postgres 2.13.1, plug 1.20.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `fe58c33` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`GET /posts?include[]=comments`, `GET /posts?fields[post][]=title`, `GET /posts?page[]=1`, `GET /posts?page[limit][]=1` (the query string decodes them to lists, in Plug and Phoenix alike).

## Observed

```
** (FunctionClauseError) no function clause matching in String.split/3
    (elixir 1.20.1) lib/string.ex:518: String.split(["comments"], ",", [])
    (ash_json_api 1.7.1) lib/ash_json_api/includes/parser.ex:14
```
`fields[post][]=title`: the same from `lib/ash_json_api/request.ex:798`. `page[]=1`: `BadMapError` from `lib/ash_json_api/controllers/helpers.ex:1013`. `page[limit][]=1`: `FunctionClauseError` in `Integer.parse/2`. Each escapes the router unrescued (a 500). `sort[]=title` answers 400 with `invalid_sort` and `invalid_query` errors, the latter from the route's own hrefSchema, which types `include` as a string too; includes and page params are read before that schema is validated.

## Expected

A 400 with the existing `invalid_includes`, `invalid_field` or `invalid_pagination` error.

## Failure point

`AshJsonApi.Includes.Parser.parse_and_validate_includes/2`, [lib/ash_json_api/includes/parser.ex#L10-L15](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/includes/parser.ex#L10-L15) (called from `Request.from/7` at request.ex L80, before `validate_href_schema/1`); `AshJsonApi.Request.add_fields/4`, [lib/ash_json_api/request.ex#L793-L798](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/request.ex#L793-L798); `AshJsonApi.Controllers.Helpers.add_pagination_parameter/3`, [lib/ash_json_api/controllers/helpers.ex#L1013](https://github.com/ash-project/ash_json_api/blob/v1.7.1/lib/ash_json_api/controllers/helpers.ex#L1013).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_json_apilist-valued-query-params-crash
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_json_api/list_valued_query_params_test.exs
* Run: `mix setup && mix test test/ash_json_api/list_valued_query_params_test.exs` in https://github.com/grempe/ash-fuzz-repros
