defmodule Repro.LuaSurface do
  @moduledoc """
  The ash_lua eval surface. Scripts call `blog.post.read`, `blog.post.create`
  and `blog.post.search` on it through `AshLua.Eval.run/2`.
  """
  use Ash.Resource,
    domain: Repro.Blog,
    extensions: [AshLua.EvalActions]

  eval_actions do
    resource Repro.Post, actions: [:read, :create, :search]
  end
end
