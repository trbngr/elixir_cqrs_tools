defmodule ExampleApi.Types.UserTypes do
  @moduledoc false
  use Cqrs.Absinthe
  use Cqrs.Absinthe.Relay

  alias Example.Queries.{ListUsers, GetUser, GetThings}
  alias Example.Users.Protocol.{CreateUser, SuspendUser, ReinstateUser, DoAThing}

  import ExampleApi.Resolvers.UserResolver

  derive_enum(DoAThing, :status, :thing_status)
  derive_enum(GetThings, :shit, :thing_shit)

  enum :user_status do
    value(:active)
    value(:suspended)
  end

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
    field :status, :user_status
  end

  connection(node_type: :user)

  object :user_queries do
    derive_query GetUser, list_of(:user),
      as: :user,
      except: [:name]

    derive_connection ListUsers, :user,
      as: :users,
      arg_types: [status: :user_status]

    derive_query GetThings, list_of(:user), arg_types: [shit: :thing_shit]
  end

  derive_mutation_input CreateUser

  object :user_mutations do
    derive_mutation DoAThing, :string, arg_types: [status: :thing_status]
    derive_mutation CreateUser, :user, input_object?: true, then: &fetch_user/1
    derive_mutation SuspendUser, :user, then: &fetch_user/1
    derive_mutation ReinstateUser, :user, then: &fetch_user/1
  end
end
