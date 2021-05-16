defmodule Cqrs.Query do
  @moduledoc """
  Defines a query and any filters.

  ## Options

  * `require_all_filters` - If `true`, all filters will be required. Defaults to `false`

  ## Examples

      defmodule GetUser do
        use Cqrs.Query
        alias Cqrs.QueryTest.User

        filter :email, :string, required: true

        option :exists?, :boolean,
          default: false,
          description: "If `true`, only check if the user exists."

        @impl true
        def handle_validate(filters, _opts) do
          Ecto.Changeset.validate_format(filters, :email, ~r/@/)
        end

        @impl true
        def handle_create([email: email], _opts) do
          from u in User, where: u.email == ^email
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
      ** (Cqrs.QueryError) %{email: ["can't be blank"]}

      iex> GetUser.new!(email: "wrong")
      ** (Cqrs.QueryError) %{email: ["has invalid format"]}

      iex> {:error, %{errors: errors}} = GetUser.new()
      ...> errors
      [email: {"can't be blank", [validation: :required]}]

      iex> {:error, %{errors: errors}} = GetUser.new(email: "wrong")
      ...> errors
      [email: {"has invalid format", [validation: :format]}]

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
  @type query :: Ecto.Query.t()
  @type filters :: keyword()

  @callback handle_create(filters(), opts()) :: query()
  @callback handle_validate(Ecto.Changeset.t(), opts()) :: Ecto.Changeset.t()
  @callback handle_execute(Ecto.Query.t(), opts()) ::
              {:ok, any()} | {:error, query()} | {:error, any()}

  alias Cqrs.{Documentation, Query, QueryError}

  defmacro __using__(opts \\ []) do
    require_all_filters = Keyword.get(opts, :require_all_filters, false)

    quote location: :keep do
      Module.register_attribute(__MODULE__, :filters, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: true)
      Module.register_attribute(__MODULE__, :required_filters, accumulate: true)
      Module.put_attribute(__MODULE__, :require_all_filters, unquote(require_all_filters))

      require Cqrs.Options

      import Ecto.Query
      import Cqrs.Options, only: [option: 3]
      import Query, only: [filter: 2, filter: 3]

      @options Cqrs.Options.tag_option()

      @behaviour Query
      @before_compile Query

      @impl true
      def handle_validate(changeset, _opts), do: changeset

      defoverridable handle_validate: 2
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

      Module.put_attribute(
        __MODULE__,
        :moduledoc,
        {1, moduledoc <> @filter_docs <> "\n" <> @option_docs}
      )
    end
  end

  defmacro __schema__ do
    quote location: :keep do
      use Ecto.Schema

      @primary_key false
      embedded_schema do
        Enum.map(@filters, fn
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
      defp get_opts(opts), do: Keyword.merge(@default_opts, opts)

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

      @filters {unquote(name), unquote(type), Keyword.put(unquote(opts), :required, required)}
    end
  end

  def __new__(mod, filters, required_filters, opts) when is_list(opts) do
    fields = mod.__schema__(:fields)

    query =
      struct(mod)
      |> Ecto.Changeset.cast(normalize(filters), fields)
      |> Ecto.Changeset.validate_required(required_filters)
      |> mod.handle_validate(opts)
      |> Ecto.Changeset.apply_action(:create)

    case query do
      {:ok, query} ->
        query =
          query
          |> Map.from_struct()
          |> Enum.reject(&match?({_, nil}, &1))
          |> Enum.to_list()
          |> mod.handle_create(opts)

        {:ok, query}

      {:error, query} ->
        {:error, query}
    end
  end

  def __new__!(mod, filters, required_filters, opts \\ []) when is_list(opts) do
    case __new__(mod, filters, required_filters, opts) do
      {:ok, query} -> query
      {:error, query} -> raise QueryError, query: query
    end
  end

  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values

  @doc false
  def execute(mod, {:ok, query}, opts), do: do_execute(mod, query, opts)
  def execute(_mod, {:error, query}, _opts), do: {:error, query}
  def execute(mod, %Ecto.Query{} = query, opts), do: do_execute(mod, query, opts)

  defp do_execute(mod, query, opts) do
    tag? = Keyword.get(opts, :tag?)

    query
    |> mod.handle_execute(opts)
    |> tag_result(tag?)
  end

  defp tag_result({:ok, result}, true), do: {:ok, result}
  defp tag_result({:error, result}, true), do: {:error, result}
  defp tag_result(result, true), do: {:ok, result}
  defp tag_result(result, _), do: result
end
