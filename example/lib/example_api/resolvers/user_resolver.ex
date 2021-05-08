defmodule ExampleApi.Resolvers.UserResolver do
  @moduledoc false
  alias Absinthe.Relay.Connection

  alias Example.Users

  import ExecutionResultHelper

  def fetch_user(result) do
    with {:ok, user_id} <- aggregate_id(result) do
      {:ok, Users.get_user!(id: user_id)}
    end
  end
end
