defmodule Repro.JsonApiRouter do
  @moduledoc "The JSON:API router for the domain, mounted under /api by Repro.Router."
  use AshJsonApi.Router,
    domains: [Repro.Blog],
    open_api: "/open_api",
    prefix: "/api"
end
