defmodule Repro.CheckFormatter do
  @moduledoc """
  An ExUnit formatter used by `mix repros.check`. It records every finished
  test with its tags, state, formatted failure and captured logs, and publishes
  the list in `:persistent_term` when the suite finishes.
  """
  use GenServer

  @key {__MODULE__, :results}

  def results, do: :persistent_term.get(@key, nil)

  @impl true
  def init(_opts) do
    :persistent_term.erase(@key)
    {:ok, []}
  end

  @impl true
  def handle_cast({:test_finished, %ExUnit.Test{} = test}, results) do
    {:noreply, [summarize(test) | results]}
  end

  def handle_cast({:suite_finished, _times}, results) do
    :persistent_term.put(@key, Enum.reverse(results))
    {:noreply, results}
  end

  def handle_cast(_event, results), do: {:noreply, results}

  defp summarize(test) do
    %{
      module: test.module,
      name: test.name,
      file: Path.relative_to_cwd(test.tags[:file]),
      bug: test.tags[:bug],
      signature: List.wrap(test.tags[:signature]),
      fixed_in: test.tags[:fixed_in],
      state: state(test.state),
      output: failure_text(test) <> (test.logs || "")
    }
  end

  defp state(nil), do: :passed
  defp state({:failed, _}), do: :failed
  defp state({:excluded, _}), do: :excluded
  defp state({:skipped, _}), do: :skipped
  defp state({:invalid, _}), do: :invalid

  defp failure_text(%ExUnit.Test{state: {:failed, failures}} = test) do
    ExUnit.Formatter.format_test_failure(test, failures, 1, :infinity, fn _, string -> string end)
  end

  defp failure_text(_test), do: ""
end
