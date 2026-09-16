defmodule Repro.Schema do
  @moduledoc "The GraphQL schema: Absinthe with the AshGraphql domain, nothing else."
  use Absinthe.Schema
  use AshGraphql, domains: [Repro.Blog]

  query do
  end

  mutation do
  end
end
