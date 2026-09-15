defmodule Repro.Post do
  @moduledoc """
  A post with a UUID primary key, a text attribute, an integer attribute and a
  to-many relationship. That is the whole surface the bugs need.
  """
  use Ash.Resource,
    domain: Repro.Blog,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource, AshLua.Resource]

  postgres do
    table "posts"
    repo Repro.Repo
  end

  json_api do
    type "post"
    includes [:comments]
  end

  graphql do
    type :post
  end

  actions do
    defaults [:destroy, create: [:title, :score], update: [:title, :score]]

    read :read do
      primary? true
      pagination keyset?: true, offset?: true, countable: true, required?: false
    end

    # A read action with an argument that happens to be named `limit`.
    # Used by the ash_lua "input merged under query controls" repro.
    read :search do
      argument :limit, :integer
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, public?: true
    attribute :score, :integer, public?: true
    create_timestamp :inserted_at
  end

  calculations do
    # A `match:` constraint is stored by Spark as `{Spark.Regex, :cache, [source, opts]}`
    # and AshSql copies it into the Ecto type parameters of the SQL cast. Used only by the
    # Ecto/Elixir/Spark "query error crashes while building its message" repro.
    calculate :title_slug, :string, expr(title) do
      constraints match: ~r/^[a-z]+$/
    end
  end

  relationships do
    has_many :comments, Repro.Comment, public?: true
  end
end
