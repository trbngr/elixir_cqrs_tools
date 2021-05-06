defmodule ExampleApi.Schema do
  @moduledoc false
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ExampleApi.Types

  import_types Types.UserTypes

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_mutations
  end

  def middleware(middleware, _field, _object) do
    alias ExampleApi.Middleware.ErrorHandler
    alias ExampleApi.Middleware.HandleExceptions

    HandleExceptions.apply(middleware) ++ [ErrorHandler]
  end
end
