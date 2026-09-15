# `is_nil` with a non-boolean value is an UnknownError

Versions: ash 3.33.3, Elixir 1.20.1 on OTP 29. Present on the default branch at `a7a5105` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`Post |> Ash.Query.filter_input(%{"title" => %{"is_nil" => "maybe"}}) |> Ash.read()`. Through AshJsonApi: `GET /posts?filter[title][is_nil]=maybe`.

## Observed

```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error: "Could not cast \"maybe\" as :boolean"}]}}
```
JSON:API answers 500 `something_went_wrong`.

## Expected

`Ash.Error.Query.InvalidFilterValue` inside `Ash.Error.Invalid`; a 400 on JSON:API.

## Failure point

`Ash.Query.Operator.cast_one/2`, [lib/ash/query/operator/operator.ex#L404-L427](https://github.com/ash-project/ash/blob/v3.33.3/lib/ash/query/operator/operator.ex#L404-L427), returning `{:error, "Could not cast ..."}`; `try_cast_with_ref/3` at L239-L256.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ashis-nil-non-boolean-value
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/is_nil_non_boolean_test.exs
* Run: `mix setup && mix test test/ash/is_nil_non_boolean_test.exs` in https://github.com/grempe/ash-fuzz-repros
