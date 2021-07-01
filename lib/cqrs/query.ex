defmodule Cqrs.Query do
  alias Ecto.Changeset

  @moduledoc """
  Defines a query and any filters.

  ## Options

  * `require_all_filters` - If `true`, all filters will be required. Defaults to `false`

  ## Examples

      defmodule GetUser do
        use Cqrs.Query
        alias Cqrs.QueryTest.User

        filter :email, :string, required: true

        binding :user, User

        option :exists?, :boolean,
          default: false,
          description: "If `true`, only check if the user exists."

        @impl true
        def handle_validate(filters, _opts) do
          Changeset.validate_format(filters, :email, ~r/@/)
        end

        @impl true
        def handle_create([email: email], _opts) do
          from u in User, as: :user, where: u.email == ^email
        end

        @impl true
        def handle_execute(query, opts) do
          case Keyword.get(opts, :exists?) do
            true -> Repo.exists?(query, opts)
            false -> Repo.one(query, opts)
          end
        end
      end

  ### Creation

      iex> GetUser.new!()
      ** (Cqrs.QueryError) email can't be blank

      iex> GetUser.new!(email: "wrong")
      ** (Cqrs.QueryError) email has invalid format

      iex> {:error, errors} = GetUser.new()
      ...> errors
      %{email: ["can't be blank"]}

      iex> {:error, errors} = GetUser.new(email: "wrong")
      ...> errors
      %{email: ["has invalid format"]}

      iex> {:ok, query} = GetUser.new(email: "chris@example.com")
      ...> query
      #Ecto.Query<from u0 in User, where: u0.email == ^"chris@example.com">

  ### Execution

      iex> {:ok, user} =
      ...> GetUser.new(email: "chris@example.com")
      ...> |> GetUser.execute()
      ...> %{id: user.id, email: user.email}
      %{id: "052c1984-74c9-522f-858f-f04f1d4cc786", email: "chris@example.com"}
  """

  @type opts :: keyword()
  @type query :: any()
  @type filters :: keyword()

  @callback handle_create(filters(), opts()) :: query()
  @callback handle_validate(Changeset.t(), opts()) :: Changeset.t()
  @callback handle_execute(Ecto.Query.t(), opts()) :: {:error, query()} | {:error, any()} | any()
  @callback handle_execute!(Ecto.Query.t(), opts()) :: any()

  alias Cqrs.{Documentation, Query, QueryError, Options, InvalidValuesError}

  defmacro __using__(opts \\ []) do
    require_all_filters = Keyword.get(opts, :require_all_filters, false)

    quote location: :keep do
      Module.register_attribute(__MODULE__, :filters, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: true)
      Module.register_attribute(__MODULE__, :bindings, accumulate: true)
      Module.register_attribute(__MODULE__, :required_filters, accumulate: true)
      Module.put_attribute(__MODULE__, :require_all_filters, unquote(require_all_filters))

      require Cqrs.Options

      import Ecto.Query
      import Query, only: [filter: 2, filter: 3, binding: 2, option: 3]

      @desc nil
      @options Cqrs.Options.tag_option()

      @behaviour Query
      @before_compile Query

      @impl true
      def handle_validate(changeset, _opts), do: changeset

      @impl true
      def handle_execute!(query, opts), do: handle_execute(query, opts)

      defoverridable handle_validate: 2, handle_execute!: 2
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      Query.__module_docs__()
      Query.__introspection__()
      Query.__schema__()
      Query.__constructor__()
      Query.__execute__()

      Module.delete_attribute(__MODULE__, :filters)
      Module.delete_attribute(__MODULE__, :options)
      Module.delete_attribute(__MODULE__, :bindings)
      Module.delete_attribute(__MODULE__, :option_docs)
      Module.delete_attribute(__MODULE__, :filter_docs)
      Module.delete_attribute(__MODULE__, :required_filters)
      Module.delete_attribute(__MODULE__, :require_all_filters)
    end
  end

  defmacro __introspection__ do
    quote do
      @name __MODULE__ |> Module.split() |> Enum.reverse() |> hd() |> to_string()

      def __filters__, do: @filters
      def __required_filters__, do: @required_filters
      def __module_docs__, do: @moduledoc
      def __query__, do: __MODULE__
      def __name__, do: @name
    end
  end

  defmacro __module_docs__ do
    quote do
      require Documentation

      moduledoc = @moduledoc || ""
      @filter_docs Documentation.field_docs("Filters", @filters, @required_filters)
      @option_docs Documentation.option_docs(@options)
      @binding_docs Documentation.query_binding_docs(@bindings)

      Module.put_attribute(
        __MODULE__,
        :moduledoc,
        {1, moduledoc <> @filter_docs <> "\n" <> @binding_docs <> "\n" <> @option_docs}
      )
    end
  end

  defmacro __schema__ do
    quote location: :keep do
      use Ecto.Schema

      @primary_key false
      embedded_schema do
        Enum.map(@filters, fn
          {name, :enum, opts} ->
            Ecto.Schema.field(name, Ecto.Enum, opts)

          {name, :binary_id, opts} ->
            Ecto.Schema.field(name, Ecto.UUID, opts)

          {name, type, opts} ->
            Ecto.Schema.field(name, type, opts)
        end)
      end
    end
  end

  defmacro __constructor__ do
    quote generated: true, location: :keep do
      @default_opts Cqrs.Options.defaults()

      defp get_opts(opts) do
        Keyword.merge(@default_opts, Cqrs.Options.normalize(opts))
      end

      @spec new(Query.filters(), keyword()) :: {:ok, Ecto.Query.t()} | {:error, any()}
      @spec new!(Query.filters(), keyword()) :: Ecto.Query.t()

      require Documentation

      @doc """
      Creates a new `#{__MODULE__} query.`

      #{@filter_docs}
      """
      def new(filters \\ [], opts \\ []) when is_list(opts),
        do: Query.__new__(__MODULE__, filters, @required_filters, get_opts(opts))

      @doc """
      Creates a new `#{__MODULE__} query.`

      #{@filter_docs}
      """
      def new!(filters \\ [], opts \\ []) when is_list(opts),
        do: Query.__new__!(__MODULE__, filters, @required_filters, get_opts(opts))
    end
  end

  defmacro __execute__ do
    quote generated: true, location: :keep do
      def execute(query, opts \\ []) do
        Query.execute(__MODULE__, query, get_opts(opts))
      end

      def execute!(query, opts \\ []) do
        Query.execute!(__MODULE__, query, get_opts(opts))
      end
    end
  end

  @doc """
  Defines a [Query](`Cqrs.Query`) filter.

  * `:name` - any `atom`
  * `:type` - any valid [Ecto Schema](`Ecto.Schema`) type
  * `:opts` - any valid [Ecto Schema](`Ecto.Schema`) field options. Plus:

      * `:required` - `true | false`. Defaults to the `require_all_filters` option.
      * `:description` - Documentation for the field.
  """
  defmacro filter(name, type, opts \\ []) do
    quote location: :keep do
      required = Keyword.get(unquote(opts), :required, @require_all_filters)
      if required, do: @required_filters(unquote(name))

      opts =
        unquote(opts)
        |> Keyword.put(:required, required)
        |> Keyword.update(:description, @desc, &Function.identity/1)

      # reset the @desc attr
      @desc nil

      @filters {unquote(name), unquote(type), opts}
    end
  end

  @doc """
  Describes a supported option for this query.

  ## Options
  * `:default` - this default value if the option is not provided.
  * `:description` - The documentation for this option.
  """

  @spec option(name :: atom(), hint :: atom(), keyword()) :: any()
  defmacro option(name, hint, opts) do
    quote do
      Options.option(unquote(name), unquote(hint), unquote(opts))
    end
  end

  defmacro binding(name, schema) do
    quote do
      @bindings {unquote(name), unquote(schema)}
    end
  end

  def __new__(mod, filters, required_filters, opts) when is_list(opts) do
    fields = mod.__schema__(:fields)

    filters = normalize(mod, filters)

    filters =
      struct(mod)
      |> Changeset.cast(filters, fields)
      |> Changeset.validate_required(required_filters)
      |> mod.handle_validate(opts)
      |> Changeset.apply_action(:create)

    case filters do
      {:ok, filters} -> create_query(mod, filters, opts)
      {:error, filters} -> {:error, format_errors(filters)}
    end
  end

  defp create_query(mod, filters, opts) do
    query =
      filters
      |> Map.from_struct()
      |> Enum.reject(&match?({_, nil}, &1))
      |> Enum.to_list()
      |> mod.handle_create(opts)

    case query do
      {:error, error} -> {:error, %{query: error}}
      {:ok, query} -> {:ok, query}
      query -> {:ok, query}
    end
  end

  def __new__!(mod, filters, required_filters, opts \\ []) when is_list(opts) do
    case __new__(mod, filters, required_filters, opts) do
      {:ok, query} -> query
      {:error, errors} -> raise QueryError, errors: errors
    end
  end

  defp format_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp normalize(_mod, values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(_mod, values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(_mod, values) when is_map(values), do: values
  defp normalize(mod, _other), do: raise(InvalidValuesError, module: mod)

  @doc false
  def execute(mod, {:ok, query}, opts), do: do_execute(mod, :handle_execute, query, opts)
  def execute(_mod, {:error, query}, _opts), do: {:error, query}
  def execute(mod, %Ecto.Query{} = query, opts), do: do_execute(mod, :handle_execute, query, opts)

  @doc false
  def execute!(mod, {:ok, query}, opts), do: do_execute(mod, :handle_execute!, query, opts)
  def execute!(_mod, {:error, query}, _opts), do: {:error, query}
  def execute!(mod, %Ecto.Query{} = query, opts), do: do_execute(mod, :handle_execute!, query, opts)

  defp do_execute(mod, execute_fun, query, opts) do
    tag? = Keyword.get(opts, :tag?)

    mod
    |> apply(execute_fun, [query, opts])
    |> tag_result(tag?)
  end

  defp tag_result({:ok, result}, true), do: {:ok, result}
  defp tag_result({:error, result}, true), do: {:error, result}
  defp tag_result(result, true), do: {:ok, result}
  defp tag_result(result, _), do: result
end
