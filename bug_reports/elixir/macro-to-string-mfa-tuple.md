# Macro.to_string/1 crashes instead of inspecting a three-tuple whose second element is not a keyword list

Versions: Elixir 1.18.4, 1.19.5, 1.20.1 and 1.20.2 on OTP 27 to 29. Present on the default branch at `39164ec` (checked 2026-09-15).

Found by an AI assistant working with a human who was fuzz-testing their own application; reproduced in a minimal project with default settings.

## Request

`Macro.to_string({Foo, :cache, ["a", []]})`.

## Observed

```
** (FunctionClauseError) no function clause matching in Access.get/3
    (elixir 1.20.1) lib/access.ex: Access.get(:cache, :line, nil)
    (elixir 1.20.1) lib/code/normalizer.ex:586: Code.Normalizer.patch_meta_line/2
    (elixir 1.20.1) lib/code/normalizer.ex:323: Code.Normalizer.normalize_call/2
```
The docs say invalid nodes are inspected to aid debugging, and other non-AST terms are: `Macro.to_string({1, 2, 3})` renders `{1, 2, 3}` and `{Foo, :cache, "x"}` renders too. Only a three-tuple with an atom in the metadata position and a list or atom in the third position crashes. Same on 1.18.4, 1.19.5, 1.20.2 and main. In practice such tuples reach `Macro.to_string/1` through Ecto, which renders query type parameters and interpolated values with it (reported to Ecto separately).

## Expected

The node is inspected, as `{Foo, :cache, ["a", []]}`, like the other invalid inputs.

## Failure point

`Code.Normalizer` matches the tuple as a call at [lib/elixir/lib/code/normalizer.ex#L228-L230](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L228-L230); `normalize_call/2` passes `:cache` to `patch_meta_line/2`, which reads `meta[:line]`, [L322-L323](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L322-L323) and [L585-L586](https://github.com/elixir-lang/elixir/blob/v1.20.1/lib/elixir/lib/code/normalizer.ex#L585-L586). `Code.Formatter` reads the metadata the same way.

## Reproduction

* Description, with the failure point at this release: https://github.com/grempe/ash-fuzz-repros#elixirmacro-to-string-mfa-tuple
* Failing test: https://github.com/grempe/ash-fuzz-repros/blob/main/test/elixir/macro_to_string_mfa_tuple_test.exs
* Run: `mix setup && mix test test/elixir/macro_to_string_mfa_tuple_test.exs` in https://github.com/grempe/ash-fuzz-repros
