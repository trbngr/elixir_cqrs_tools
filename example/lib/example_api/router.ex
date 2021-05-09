defmodule ExampleApi.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.Controller

  pipeline :api do
    plug Plug.Logger, log: :debug
    plug :accepts, ["json"]
    plug :put_secure_browser_headers
    plug ExampleApi.Plug.AbsintheContext
  end

  scope "/" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: ExampleApi.Schema,
      interface: :simple

    forward "/", Absinthe.Plug, schema: ExampleApi.Schema
  end
end
