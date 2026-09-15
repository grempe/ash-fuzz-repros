defmodule Repro.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([Repro.Repo], strategy: :one_for_one, name: Repro.Supervisor)
  end
end
