defmodule Repro.JsonApiRouter do
  use AshJsonApi.Router,
    domains: [Repro.Blog],
    open_api: "/open_api",
    prefix: "/api"
end
