# Bug reports for ash-project/ash

These were found by an AI assistant working with a human who was fuzz-testing their own application, then reduced to a minimal project with default settings (ash 3.33.3, Elixir 1.20.1 on OTP 29). Every one has a deterministic failing test in https://github.com/grempe/ash-fuzz-repros; `mix setup && mix test` runs them all, and the README describes each bug with its failure point at this release.

One file per bug, ready to file, is in this directory.

| Bug | Details |
|---|---|
| filter_input crashes on `and` / `or` with a value that is not a non-empty list or map | [README](https://github.com/grempe/ash-fuzz-repros#ashfilter-combinator-shape), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/filter_combinator_shape_test.exs), [draft](ash/filter-combinator-shape.md) |
| `is_nil` with a non-boolean value is an UnknownError | [README](https://github.com/grempe/ash-fuzz-repros#ashis-nil-non-boolean-value), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/is_nil_non_boolean_test.exs), [draft](ash/is-nil-non-boolean-value.md) |
| Input filters do not check a predicate's argument types against the referenced attribute | [README](https://github.com/grempe/ash-fuzz-repros#ashpredicate-argument-types-unchecked), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/predicate_argument_types_unchecked_test.exs), [draft](ash/predicate-argument-types-unchecked.md) |
| Invalid `page` options are an unrendered Spark.Options.ValidationError, and a non-list `page` raises | [README](https://github.com/grempe/ash-fuzz-repros#ashinvalid-page-options-unrendered), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/invalid_page_options_test.exs), [draft](ash/invalid-page-options-unrendered.md) |
| sort_input crashes on a value that is neither a string nor a list | [README](https://github.com/grempe/ash-fuzz-repros#ashsort-input-shape), [test](https://github.com/grempe/ash-fuzz-repros/blob/main/test/ash/sort_input_shape_test.exs), [draft](ash/sort-input-shape.md) |
