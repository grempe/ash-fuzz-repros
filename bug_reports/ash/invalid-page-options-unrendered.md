# Invalid `page` options are an unrendered Spark.Options.ValidationError, and a non-list `page` raises

Versions: ash 3.33.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `a7a5105` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

On a read action with `pagination keyset?: true, offset?: true`: `Ash.read(Post, page: [after: "x", offset: 1])`; also `page: [limit: 0]`, `[limit: -1]`, `[limit: "x"]`, `[limit: 1, offset: -1]`. Through AshJsonApi: `GET /posts?page[after]=x&page[offset]=1`. And `Ash.read(Post, page: "x")`.

## Observed

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (Spark.Options.ValidationError) invalid value for :page option: unknown options [:offset], valid options are: [:before, :after, :limit, :filter, :count]"}]}}
```
(`expected positive integer, got: 0` and so on for the others.) JSON:API answers 500. `page: "x"` raises `FunctionClauseError` in `Access.get/3`. By contrast `page: [after: "x", limit: 1]` returns `Ash.Error.Invalid` with `Ash.Error.Page.InvalidKeyset`.

## Expected

An `Ash.Error.Invalid` describing the bad page options; a 400 on JSON:API.

## Failure point

`Ash.Page.page_opts/1`, [lib/ash/page/page.ex#L16-L33](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/page/page.ex#L16-L33); the failure reaches `Ash.Error.to_error_class/2` from [lib/ash.ex#L3149-L3150](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash.ex#L3149-L3150).

## Notes

AshGraphql hits the same unrendered error with `first: 0` (reported there).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ashinvalid-page-options-unrendered
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/invalid_page_options_test.exs
* Run: `mix setup && mix test test/ash/invalid_page_options_test.exs` in https://github.com/grempe/ash-fuzz-repros
