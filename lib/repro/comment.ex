defmodule Repro.Comment do
  @moduledoc false
  use Ash.Resource,
    domain: Repro.Blog,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource]

  postgres do
    table "comments"
    repo Repro.Repo
  end

  json_api do
    type "comment"
  end

  graphql do
    type :comment
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_primary_key :id
    attribute :body, :string, public?: true
  end

  relationships do
    belongs_to :post, Repro.Post, public?: true
  end
end
