if Code.ensure_loaded?(Absinthe.Relay) do
  defmodule Cqrs.Absinthe.Relay do
    @moduledoc """
    Macros for `Absinthe.Relay`

    ## Optinal Application Configuration

        config :cqrs_tools, :absinthe_relay, repo: Example.Repo
    """

    require Logger

    alias Cqrs.Guards
    alias Cqrs.Absinthe.{Relay, Query}

    defmacro __using__(_) do
      quote do
        import Cqrs.Absinthe.Relay,
          only: [
            derive_connection: 3,
            connection_with_total_count: 1,
            connection_with_total_count: 2,
            connections_with_total_count: 1
          ]
      end
    end

    @doc """
    Creates an `Absinthe.Relay.Connection` query from a [Command](`Cqrs.Command`).

    ## Options

    * `:repo` - The `Ecto.Repo` to use for the connection. Defaults to the configured repo in `:cqrs_tools, :absinthe_relay`.
    * `:repo_fun` - The function of the `:repo` to run. Defaults to `:all`
    * `:as` - The name to use for the query. Defaults to the query_module name snake_cased.
    * `:only` - Use only the filters listed
    * `:except` - Create filters for all except those listed
    * `:arg_types` - A list of filter names to absinthe types. See example.
    * `:before_resolve` - [Absinthe Middleware](`Absinthe.Middleware`) to run before the resolver.
    * `:after_resolve` - [Absinthe Middleware](`Absinthe.Middleware`) to run after the resolver.
    * `:parent_mappings` - A keyword list of query filters to functions that receive the field's parent object as an argument.
    * `:filter_transforms` - A keyword list of query filters to functions that receive the filter's current value as an argument.

    ## Example

        defmodule ExampleApi.Types.UserTypes do
          @moduledoc false
          use Cqrs.Absinthe.Relay

          use Absinthe.Schema.Notation
          use Absinthe.Relay.Schema.Notation, :modern

          alias Example.Queries.ListUsers

          enum :user_status do
            value :active
            value :suspended
          end

          object :user do
            field :id, :id
            field :name, :string
            field :email, :string
            field :status, :user_status

            derive_connection GetUserFriends, :user,
              as: :friends,
              repo: Example.Repo,
              parent_mappings: [user_id: fn %{id: id} -> id end]
          end

          connection(node_type: :user)

          object :user_queries do
            derive_connection ListUsers, :user,
              as: :users,
              repo: Example.Repo,
              arg_types: [status: :user_status]
          end
        end
    """
    defmacro derive_connection(query_module, return_type, opts) do
      opts =
        opts
        |> Keyword.merge(source: query_module, macro: :derive_connection)
        |> Macro.escape()

      return_type = Macro.escape(return_type)

      field =
        quote location: :keep do
          Guards.ensure_is_query!(unquote(query_module))

          Query.create_connection_query(
            unquote(query_module),
            unquote(return_type),
            Keyword.put_new(unquote(opts), :tag?, true)
          )
        end

      Module.eval_quoted(__CALLER__, field)
    end

    def define_connection_with_total_count(node_type, opts \\ []) do
      fields = Keyword.get(opts, :do)

      quote do
        connection node_type: unquote(node_type) do
          field :total_count, :integer, resolve: &Relay.resolve_total_count/3
          unquote(fields)

          edge do
          end
        end
      end
    end

    def resolve_total_count(%{connection_query: query, repo: repo}, _args, _res) do
      total_count = repo.aggregate(query, :count, :id)
      {:ok, total_count}
    end

    def resolve_total_count(_connection, _args, _res) do
      Logger.warn("Requested total_count on a connection that was not created by cqrs_tools.")
      {:ok, nil}
    end

    @doc """
    Creates a connection type for each node_type. The connection will contain a `total_count` field.
    """
    defmacro connection_with_total_count(node_type, opts \\ []) when is_atom(node_type) do
      define_connection_with_total_count(node_type, opts)
    end

    @doc """
    Creates a connection type for each node_type. Each connection will contain a `total_count` field.
    """
    defmacro connections_with_total_count(node_types) when is_list(node_types) do
      Enum.map(node_types, &define_connection_with_total_count/1)
    end
  end
end
