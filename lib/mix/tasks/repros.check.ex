defmodule Mix.Tasks.Repros.Check do
  @shortdoc "Runs the suite and checks that every bug reproduces with its documented signature"
  @moduledoc """
  Runs the test suite with a formatter that records every result, then verifies:

    * every test tagged `bug:` failed, and its failure output (including
      captured logs) contains every string in its `signature:` tag;
    * every other test (the controls) passed;
    * nothing was skipped, excluded or invalid.

  Prints one row per bug id and exits non-zero when any check fails.

      mix repros.check
      mix repros.check --seed 12345
  """
  use Mix.Task

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [seed: :integer])
    seed = opts[:seed] || Enum.random(0..1_000_000)

    Mix.Task.run("test", [
      "--formatter",
      "Repro.CheckFormatter",
      "--seed",
      Integer.to_string(seed)
    ])

    results = Repro.CheckFormatter.results() || Mix.raise("the formatter recorded no results")
    {bug_tests, control_tests} = Enum.split_with(results, &(&1.bug != nil))

    rows = bug_tests |> Enum.group_by(& &1.bug) |> Enum.sort() |> Enum.map(&row/1)
    control_problems = Enum.reject(control_tests, &(&1.state == :passed))

    print_table(rows, seed)
    Enum.each(control_problems, &Mix.shell().error("control test did not pass: #{describe(&1)}"))

    problems = Enum.flat_map(rows, & &1.problems) ++ Enum.map(control_problems, &describe/1)

    Mix.shell().info(
      "\n#{length(bug_tests)} bug tests, #{length(control_tests)} control tests, seed #{seed}"
    )

    if problems == [] do
      Mix.shell().info("All bugs reproduced with their documented signatures.")
      System.halt(0)
    else
      Mix.shell().error("#{length(problems)} problem(s) found.")
      System.halt(1)
    end
  end

  defp row({bug, tests}) do
    [repo | _] = String.split(bug, "/", parts: 2)
    signatures = tests |> Enum.map(& &1.signature) |> Enum.uniq()

    problems =
      Enum.flat_map(tests, fn test ->
        cond do
          test.state != :failed ->
            ["#{describe(test)}: expected a failure, got #{test.state}"]

          true ->
            test.signature
            |> Enum.reject(&String.contains?(test.output, &1))
            |> Enum.map(&"#{describe(test)}: failure output lacks #{inspect(&1)}")
        end
      end)

    %{
      bug: bug,
      repo: repo,
      signature: signatures |> Enum.map(&Enum.join(&1, " + ")) |> Enum.join(" | "),
      tests: length(tests),
      problems: problems,
      result: if(problems == [], do: "reproduced (#{length(tests)} tests)", else: "PROBLEM")
    }
  end

  defp describe(test), do: "#{test.file}: #{test.name}"

  defp print_table(rows, seed) do
    headers = ["bug id", "upstream repository", "expected signature", "result"]

    cells =
      Enum.map(rows, fn row ->
        [row.bug, "#{upstream(row.repo)}", row.signature, row.result]
      end)

    widths =
      [headers | cells]
      |> Enum.zip_with(fn column -> column |> Enum.map(&String.length/1) |> Enum.max() end)

    line = fn cells ->
      cells
      |> Enum.zip(widths)
      |> Enum.map_join(" | ", fn {cell, width} -> String.pad_trailing(cell, width) end)
      |> String.trim_trailing()
    end

    Mix.shell().info("\nRepro check (seed #{seed})\n")
    Mix.shell().info(line.(headers))
    Mix.shell().info(Enum.map_join(widths, "-+-", &String.duplicate("-", &1)))
    Enum.each(cells, &Mix.shell().info(line.(&1)))

    rows
    |> Enum.flat_map(& &1.problems)
    |> Enum.each(&Mix.shell().error("  " <> &1))
  end

  @upstream %{
    "ash" => "ash-project/ash",
    "ash_postgres" => "ash-project/ash_postgres",
    "ash_json_api" => "ash-project/ash_json_api",
    "ash_graphql" => "ash-project/ash_graphql",
    "ash_lua" => "ash-project/ash_lua",
    "ash_ai" => "ash-project/ash_ai",
    "absinthe" => "absinthe-graphql/absinthe",
    "ecto" => "elixir-ecto/ecto",
    "elixir" => "elixir-lang/elixir"
  }

  defp upstream(repo), do: Map.get(@upstream, repo, repo)
end
