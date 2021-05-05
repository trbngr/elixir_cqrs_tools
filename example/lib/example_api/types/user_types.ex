defmodule ExampleApi.Types.UserTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  import ExampleApi.Resolvers.UserResolver

  enum :user_status do
    value :active
    value :suspended
  end

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
    field :status, :user_status
  end

  connection(node_type: :user)

  object :user_queries do
    connection field :users, node_type: :user do
      arg :status, :user_status
      arg :email, :string
      arg :name, :string
      resolve &users/2
    end
  end

  input_object :create_user_input do
    field :name, non_null(:string)
    field :email, non_null(:string)
  end

  object :user_mutations do
    field :create_user, :user do
      arg :input, non_null(:create_user_input)
      resolve &create_user/2
    end

    field :suspend_user, :user do
      arg :id, non_null(:id)
      resolve &suspend_user/2
    end

    field :reinstate_user, :user do
      arg :id, non_null(:id)
      resolve &reinstate_user/2
    end
  end
end
