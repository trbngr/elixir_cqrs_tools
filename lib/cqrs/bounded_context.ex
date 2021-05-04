defmodule Cqrs.BoundedContext do
  alias Cqrs.{BoundedContext, Command, Query}
  @moduledoc """
  Macros to create proxy functions to [commands](`#{Command}`) and [queries](`#{Query}`) in a module.

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
      ** (Cqrs.Query.QueryError) %{email: ["can't be blank"]}

      iex> Users.get_user2!()
      ** (Cqrs.Query.QueryError) %{email: ["can't be blank"]}

      iex> Users.get_user!(email: "wrong")
      ** (Cqrs.Query.QueryError) %{email: ["has invalid format"]}

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
      import BoundedContext, only: [command: 1, command: 2, query: 1, query: 2]
    end
  end

  defmacro query(command, opts \\ []) do
    function_name = BoundedContext.__function_name__(command, opts)

    quote do
      def unquote(function_name)(attrs \\ [], opts \\ []) do
        BoundedContext.__execute_query__(unquote(command), attrs, opts)
      end

      def unquote(:"#{function_name}!")(attrs \\ [], opts \\ []) do
        BoundedContext.__execute_query__!(unquote(command), attrs, opts)
      end

      def unquote(:"#{function_name}_query")(attrs \\ [], opts \\ []) do
        BoundedContext.__create_query__(unquote(command), attrs, opts)
      end

      def unquote(:"#{function_name}_query!")(attrs \\ [], opts \\ []) do
        BoundedContext.__create_query__!(unquote(command), attrs, opts)
      end
    end
  end

  defmacro command(command, opts \\ []) do
    function_name = BoundedContext.__function_name__(command, opts)

    quote do
      def unquote(function_name)(attrs \\ [], opts \\ []) do
        BoundedContext.__dispatch_command__(unquote(command), attrs, opts)
      end

      def unquote(:"#{function_name}!")(attrs \\ [], opts \\ []) do
        BoundedContext.__dispatch_command__!(unquote(command), attrs, opts)
      end
    end
  end

  def __function_name__({_, _, module}, opts) do
    [name | _] = Enum.reverse(module)

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

  def __create_query__(module, attrs, opts) do
    module.new(attrs, opts)
  end

  def __create_query__!(module, attrs, opts) do
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
