defmodule ExampleApi.Resolvers.UserResolver do
  @moduledoc false
  alias Absinthe.Relay.Connection

  alias Example.Repo
  alias Example.Users

  import ExecutionResultHelper

  def users(args, _res) do
    args
    |> Users.list_users_query!()
    |> Connection.from_query(&Repo.all/1, args)
  end

  def create_user(%{input: input}, _res) do
    Users.create_user(input, then: &fetch_user/1)
  end

  def suspend_user(args, _res) do
    Users.suspend_user(args, then: &fetch_user/1)
  end

  def reinstate_user(args, _res) do
    Users.reinstate_user(args, then: &fetch_user/1)
  end

  defp fetch_user(result) do
    with {:ok, user_id} <- aggregate_id(result) do
      {:ok, Users.get_user!(id: user_id)}
    end
  end
end
