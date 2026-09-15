defmodule Repro.Absinthe.LoneSurrogateEscapeTest do
  @moduledoc """
  absinthe-graphql/absinthe: a string literal with an escaped lone surrogate
  (`"a\\ud800b"`) makes the lexer call `:unicode.characters_to_binary/1` on a
  code point that is not a scalar value. The lexer ignores the error tuple it
  gets back and emits a malformed token; the parser then raises `ArgumentError`
  converting it, and `Absinthe.Phase.Parse` renders every rescued exception
  with `Exception.message/1`, so the client sees Erlang's argument error text.
  A surrogate pair (`"\\ud83d\\ude00"`, the fixed-width spelling of U+1F600)
  fails the same way, because escapes are converted one at a time.
  No Ash is involved: this file uses its own one-field schema.
  """
  use ExUnit.Case, async: false

  @bug "absinthe/lone-surrogate-escape-leaks-argument-error"
  @signature ["An unknown error occurred during parsing"]

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :echo, :string do
        arg(:value, non_null(:string))
        resolve(fn %{value: value}, _ -> {:ok, value} end)
      end
    end
  end

  test "control: a valid unicode escape parses and resolves" do
    assert {:ok, %{data: %{"echo" => "aéb"}}} = Absinthe.run(~S|{ echo(value: "aéb") }|, Schema)
  end

  @tag bug: @bug, signature: @signature
  test "a lone surrogate escape is a syntax error without exception text" do
    assert {:ok, %{errors: [%{message: message}]}} =
             Absinthe.run(~S|{ echo(value: "a\ud800b") }|, Schema)

    refute message =~ "unknown error"
    refute message =~ "errors were found at the given arguments"
  end

  @tag bug: @bug, signature: @signature
  test "a surrogate pair escape resolves to the code point" do
    assert {:ok, %{data: %{"echo" => "\u{1F600}"}}} =
             Absinthe.run(~S|{ echo(value: "\ud83d\ude00") }|, Schema)
  end
end
