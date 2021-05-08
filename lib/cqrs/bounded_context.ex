defmodule Cqrs.BoundedContext do
  alias Cqrs.{BoundedContext, Guards}

  @moduledoc """
  Macros to create proxy functions to [commands](`Cqrs.Command`) and [queries](`Cqrs.Query`) in a module.

  ## Examples
      defmodule Users do
        use Cqrs.BoundedContext

        command CreateUser
        command CreateUser, as: :create_user2

        query GetUser
        query GetUser, as: :get_user2
      end

  ### Commands

      iex> {:error, {:invalid_command, state}} =
      ...> Users.create_user(name: "chris", email: "wrong")
      ...> state.errors
      %{email: ["has invalid format"]}

      iex> {:error, {:invalid_command, state}} =
      ...> Users.create_user2(name: "chris", email: "wrong")
      ...> state.errors
      %{email: ["has invalid format"]}

      iex> Users.create_user(name: "chris", email: "chris@example.com")
      {:ok, :dispatched}

      iex> Users.create_user2(name: "chris", email: "chris@example.com")
      {:ok, :dispatched}

  ### Queries

      iex> Users.get_user!()
      ** (Cqrs.QueryError) %{email: ["can't be blank"]}

      iex> Users.get_user2!()
      ** (Cqrs.QueryError) %{email: ["can't be blank"]}

      iex> Users.get_user!(email: "wrong")
      ** (Cqrs.QueryError) %{email: ["has invalid format"]}

      iex> {:error, %{errors: errors}} = Users.get_user()
      ...> errors
      [email: {"can't be blank", [validation: :required]}]

      iex> {:error, %{errors: errors}} = Users.get_user(email: "wrong")
      ...> errors
      [email: {"has invalid format", [validation: :format]}]

      iex> {:ok, query} = Users.get_user_query(email: "chris@example.com")
      ...> query
      #Ecto.Query<from u0 in User, where: u0.email == ^"chris@example.com">

      iex> {:ok, user} = Users.get_user(email: "chris@example.com")
      ...> %{id: user.id, email: user.email}
      %{id: "052c1984-74c9-522f-858f-f04f1d4cc786", email: "chris@example.com"}
  """

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :queries, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      import BoundedContext, only: [command: 1, command: 2, query: 1, query: 2]

      @before_compile BoundedContext
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      commands = Enum.map(@commands, &BoundedContext.__command_proxy__/1)
      queries = Enum.map(@queries, &BoundedContext.__query_proxy__/1)

      Module.eval_quoted(__ENV__, commands)
      Module.eval_quoted(__ENV__, queries)

      Module.delete_attribute(__MODULE__, :queries)
      Module.delete_attribute(__MODULE__, :commands)
    end
  end

  @doc """
  Creates proxy functions to dispatch this command module.

  ## Functions created

  When given `CreateUser`

  * `create_user!/0`
  * `create_user!/1`
  * `create_user!/2`
  * `create_user/0`
  * `create_user/1`
  * `create_user/2`

  ## Options

  * `:after` - A function of one arity to run with the execution result.
  """
  defmacro command(command_module, opts \\ []) do

    quote location: :keep do
      Guards.ensure_is_command!(unquote(command_module))
      function_name = BoundedContext.__function_name__(unquote(command_module), unquote(opts))

      then =
        case Keyword.get(unquote(opts), :after, []) do
          [] -> &Function.identity/1
          fun when is_function(fun, 1) -> fun
          list when is_list(list) -> Keyword.get(list, function_name, &Function.identity/1)
        end

      @commands {unquote(command_module), function_name, [then: then]}
    end
  end

  def __command_proxy__({command_module, function_name, opts}) do
    quote do
      @doc """
      #{unquote(command_module).__module_docs__()}
      #{unquote(command_module).__field_docs__()}
      """
      def unquote(function_name)(attrs \\ [], opts \\ []) do
        opts = Keyword.merge(unquote(opts), opts)
        BoundedContext.__dispatch_command__(unquote(command_module), attrs, opts)
      end

      @doc """
      #{unquote(command_module).__module_docs__()}
      #{unquote(command_module).__field_docs__()}
      """
      def unquote(:"#{function_name}!")(attrs \\ [], opts \\ []) do
        opts = Keyword.merge(unquote(opts), opts)
        BoundedContext.__dispatch_command__!(unquote(command_module), attrs, opts)
      end
    end
  end

  @doc """
  Creates proxy functions to create and execute the give query.

  ## Functions created

  When given `ListUsers`

  * `list_users!/0`
  * `list_users!/1`
  * `list_users!/2`
  * `list_users/0`
  * `list_users/1`
  * `list_users/2`
  * `list_users_query!/0`
  * `list_users_query!/1`
  * `list_users_query!/2`
  * `list_users_query/0`
  * `list_users_query/1`
  * `list_users_query/2`
  """
  defmacro query(query_module, opts \\ []) do

    quote location: :keep do
      Guards.ensure_is_query!(unquote(query_module))
      function_name = BoundedContext.__function_name__(unquote(query_module), unquote(opts))
      @queries {unquote(query_module), function_name}
    end
  end

  def __query_proxy__({query_module, function_name}) do
    quote do
      @doc """
      #{unquote(query_module).__module_docs__()}
      #{unquote(query_module).__filter_docs__()}
      """
      def unquote(function_name)(filters \\ [], opts \\ []) do
        BoundedContext.__execute_query__(unquote(query_module), filters, opts)
      end

      @doc """
      #{unquote(query_module).__module_docs__()}
      #{unquote(query_module).__filter_docs__()}
      """
      def unquote(:"#{function_name}!")(filters \\ [], opts \\ []) do
        BoundedContext.__execute_query__!(unquote(query_module), filters, opts)
      end

      query = unquote(query_module).__query__()
      query_headline_modifier = if query =~ ~r/^[aeiou]/i, do: "an", else: "a"

      @doc """
      Creates #{query_headline_modifier} [#{query}](`#{unquote(query_module)}`) query without executing it.
      #{unquote(query_module).__filter_docs__()}
      """
      def unquote(:"#{function_name}_query")(filters \\ [], opts \\ []) do
        BoundedContext.create_query(unquote(query_module), filters, opts)
      end

      @doc """
      Creates #{query_headline_modifier} [#{query}](`#{unquote(query_module)}`) query without executing it.
      #{unquote(query_module).__filter_docs__()}
      """
      def unquote(:"#{function_name}_query!")(filters \\ [], opts \\ []) do
        BoundedContext.create_query!(unquote(query_module), filters, opts)
      end
    end
  end

  def __function_name__(module, opts) do
    [name | _] =
      module
      |> Module.split()
      |> Enum.reverse()

    default_function_name =
      name
      |> to_string
      |> Macro.underscore()
      |> String.to_atom()

    Keyword.get(opts, :as, default_function_name)
  end

  def __dispatch_command__(module, attrs, opts) do
    then = Keyword.get(opts, :then, &Function.identity/1)

    attrs
    |> module.new(opts)
    |> module.dispatch(opts)
    |> __handle_command_result__(then)
  end

  def __dispatch_command__!(module, attrs, opts) do
    then = Keyword.get(opts, :then, &Function.identity/1)

    attrs
    |> module.new!(opts)
    |> module.dispatch(opts)
    |> __handle_command_result__(then)
  end

  def __handle_command_result__(result, fun) when is_function(fun, 1), do: fun.(result)

  def __handle_command_result__(_result, _other), do: raise("'then' should be a function/1")

  def create_query(module, attrs, opts) do
    module.new(attrs, opts)
  end

  def create_query!(module, attrs, opts) do
    module.new!(attrs, opts)
  end

  def __execute_query__(module, attrs, opts) do
    attrs
    |> module.new(opts)
    |> module.execute(opts)
  end

  def __execute_query__!(module, attrs, opts) do
    attrs
    |> module.new!(opts)
    |> module.execute(opts)
  end

end
