# A lone surrogate escape, or a surrogate pair escape, leaks Erlang's ArgumentError text

Versions: absinthe 1.12.0, Elixir 1.20.1 on OTP 29. Present on the default branch at `1372ceb` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

Any document with a string literal containing an escaped lone surrogate, for example `{ echo(value: "a\ud800b") }`, or an escaped surrogate pair, `{ echo(value: "\ud83d\ude00") }` (the fixed-width spelling of U+1F600 that the spec keeps for compatibility). Self-contained, no database:
```elixir
Mix.install([{:absinthe, "1.12.0"}])

defmodule Schema do
  use Absinthe.Schema

  query do
    field :echo, :string do
      arg :value, non_null(:string)
      resolve fn %{value: value}, _ -> {:ok, value} end
    end
  end
end

Absinthe.run(~S|{ echo(value: "a\ud800b") }|, Schema)
Absinthe.run(~S|{ echo(value: "\ud83d\ude00") }|, Schema)
```

## Observed

```
{:ok, %{errors: [%{message: "An unknown error occurred during parsing: errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n"}]}}
```
for both documents. The error carries no `locations`. (The second line of the message is OTP's error formatting and may read differently on older OTP.) `\u{1F600}`, `\uZZZZ` and `\u12` pass through as literal text.

## Expected

A syntax error with a location for the lone surrogate, and U+1F600 for the pair, with no exception text in either case.

## Failure point

`unescape_unicode/5`, [lib/absinthe/lexer.ex#L367-L372](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/lexer.ex#L367-L372), ignores the `{:error, _, _}` return of `:unicode.characters_to_binary/1`; `extract_quoted_string_token/1`, [src/absinthe_parser.yrl#L422-L423](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/src/absinthe_parser.yrl#L422-L423), then raises; `Absinthe.Phase.Parse` rescues at [lib/absinthe/phase/parse.ex#L86-L88](https://github.com/absinthe-graphql/absinthe/blob/v1.12.0/lib/absinthe/phase/parse.ex#L86-L88) and renders `Exception.message/1` at L116-L127.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#absinthelone-surrogate-escape-leaks-argument-error
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/absinthe/lone_surrogate_escape_test.exs
* Run: `mix setup && mix test test/absinthe/lone_surrogate_escape_test.exs` in https://github.com/grempe/ash-fuzz-repros
