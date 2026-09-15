defmodule Repro.Blog do
  @moduledoc """
  The single Ash domain. Every surface (JSON:API, GraphQL, Lua, MCP) is wired
  here so that each bug can be reproduced through the transport it was seen on.
  """
  use Ash.Domain,
    otp_app: :repro,
    extensions: [AshJsonApi.Domain, AshGraphql.Domain, AshLua.Domain, AshAi]

  json_api do
    routes do
      base_route "/posts", Repro.Post do
        index :read
        get :read
        post :create
        patch :update
      end
    end
  end

  graphql do
    queries do
      get Repro.Post, :get_post, :read
      list Repro.Post, :list_posts, :read
    end

    mutations do
      create Repro.Post, :create_post, :create
    end
  end

  tools do
    tool :read_posts, Repro.Post, :read
  end

  resources do
    resource Repro.Post
    resource Repro.Comment
    resource Repro.LuaSurface
  end
end
