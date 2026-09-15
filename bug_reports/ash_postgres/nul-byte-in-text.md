# A NUL byte in text is an unconverted Postgrex.Error

Versions: ash_postgres 2.13.1, ash_sql 0.7.5, ash 3.33.3, ecto 3.14.2, postgrex 0.22.4, PostgreSQL 18.6, Elixir 1.20.1 on OTP 29. Present on the default branch at `97ffea9` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

A title containing a NUL byte (0x00): `Ash.create(Post, %{title: "a" <> <<0>> <> "b"})` and `Post |> Ash.Query.filter(title == "a" <> <<0>> <> "b") |> Ash.read()`. Through AshJsonApi: `POST /posts` with that title and `GET /posts?filter[title]=a%00b`. Through AshGraphql: `createPost` with the value as a variable or as a `\u0000` escape. Through ash_lua: `blog.post.create` with a Lua string literal containing the byte.

## Observed

The server rejects the value and the error is returned as unknown-class:
```
{:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error:
  "** (Postgrex.Error) ERROR 22021 (character_not_in_repertoire) invalid byte sequence for encoding \"UTF8\": 0x00"}]}}
```
JSON:API answers 500; GraphQL answers "something went wrong"; Lua gets `unknown_error`. Invalid UTF-8 (`0xff`, reachable through a Lua literal) fails identically.

## Expected

An invalid-class error, as a constraint violation from the same server already gets (`Ash.Error.Changes.InvalidAttribute` for a create, `Ash.Error.Query.InvalidFilterValue` for a filter); a 400 on JSON:API. The Postgres error names no column, so attributing it to the attribute needs the changeset.

## Failure point

`handle_raised_error/4` in [lib/data_layer.ex](https://github.com/ash-project/ash_postgres/blob/v2.13.1/lib/data_layer.ex): the `Postgrex.Error` clauses at L3195, L3218, L3241, L3261, L3279 and L3298 all end in `to_constraints/2`, which yields nothing for `22021`; a create returns `to_ash_error/2` from L3269, a read from the catch-all clause.

## Notes

Postgrex maintainers consider input sanitising the application's job (elixir-ecto/postgrex#568, "Need way to sanitize string input", closed).

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#ash_postgresnul-byte-in-text
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash_postgres/nul_byte_in_text_test.exs
* Run: `mix setup && mix test test/ash_postgres/nul_byte_in_text_test.exs` in https://github.com/grempe/ash-fuzz-repros
