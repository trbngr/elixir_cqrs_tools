defmodule Persona do
  use Cqrs.ValueObject

  field :name, :string
  field :dob, :date
end

defmodule ChangeWidgetStatus do
  use Cqrs.Command

  field :status, :enum, values: [:new, :old]
  field :persona, Persona

  @impl true
  def handle_dispatch(command, _opts) do
    {:ok, command}
  end
end

defmodule WidgetTypes do
  use Cqrs.Absinthe
  use Absinthe.Schema.Notation

  derive_enum :widget_status, {ChangeWidgetStatus, :status}
  derive_input_object :persona_input, Persona

  object :widget do
    field :status, :widget_status
  end

  object :widget_mutations do
    derive_mutation ChangeWidgetStatus, :widget,
      arg_types: [
        status: :widget_status,
        persona: :persona_input
      ]
  end
end

defmodule UserResolvers do
  def before_get_user_resolver(res, _) do
    send(self(), :before_resolve)
    res
  end
end

defmodule TempRepo do
  def all_users(_) do
    [
      %User{
        email: "chris@example.com",
        id: "052c1984-74c9-522f-858f-f04f1d4cc786",
        name: "chris"
      }
    ]
  end

  def all_friends(%Ecto.Query{wheres: [%{params: params}]}) do
    send(self(), {:friends_query_params, params})
    []
  end
end

defmodule TestAssignParentToField do
  use Cqrs.Command

  field :current_user, :map

  def handle_dispatch(%{current_user: user}, _opts) do
    {:ok, user}
  end
end

defmodule UserTypes do
  use Cqrs.Absinthe
  use Cqrs.Absinthe.Relay
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string

    derive_mutation TestAssignParentToField, :user,
      as: :assign_parent,
      parent_mappings: [current_user: &Function.identity/1]

    derive_query GetUserFriends, list_of(:user),
      as: :friends,
      parent_mappings: [user_id: & &1.id]

    derive_connection GetUserFriends, :user,
      as: :friends_connection,
      parent_mappings: [user_id: & &1.id],
      repo: TempRepo,
      repo_fun: :all_friends
  end

  connection(node_type: :user)

  object :user_queries do
    derive_query GetUser, :user,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end

    derive_connection GetUsers, :user,
      repo: TempRepo,
      repo_fun: :all_users,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end

  object :user_mutations do
    derive_mutation CreateUser, :string,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end
end

defmodule UserResolvers do
  def before_get_user_resolver(res, _) do
    send(self(), :before_resolve)
    res
  end
end

defmodule TempRepo do
  def all_users(_) do
    [
      %User{
        email: "chris@example.com",
        id: "052c1984-74c9-522f-858f-f04f1d4cc786",
        name: "chris"
      }
    ]
  end

  def all_friends(%Ecto.Query{wheres: [%{params: params}]}) do
    send(self(), {:friends_query_params, params})
    []
  end
end

defmodule TestAssignParentToField do
  use Cqrs.Command

  field :current_user, :map

  def handle_dispatch(%{current_user: user}, _opts) do
    {:ok, user}
  end
end

defmodule UserTypes do
  use Cqrs.Absinthe
  use Cqrs.Absinthe.Relay
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string

    derive_mutation TestAssignParentToField, :user,
      as: :assign_parent,
      parent_mappings: [current_user: &Function.identity/1]

    derive_query GetUserFriends, list_of(:user),
      as: :friends,
      parent_mappings: [user_id: & &1.id]

    derive_connection GetUserFriends, :user,
      as: :friends_connection,
      parent_mappings: [user_id: & &1.id],
      repo: TempRepo,
      repo_fun: :all_friends
  end

  connection(node_type: :user)

  object :user_queries do
    derive_query GetUser, :user,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end

    derive_connection GetUsers, :user,
      repo: TempRepo,
      repo_fun: :all_users,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end

  object :user_mutations do
    derive_mutation CreateUser, :string,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end
end

defmodule AbsintheSchema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types UserTypes
  import_types WidgetTypes
  import_types Absinthe.Type.Custom

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_mutations
    import_fields :widget_mutations
  end
end
