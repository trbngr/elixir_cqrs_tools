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
          {:ok, Repo.all(query, opts)}
        end
      end

  ### Creation

      iex> GetUser.new!()
      ** (Cqrs.Query.QueryError) %{email: ["can't be blank"]}

      iex> GetUser.new!(email: "wrong")
      ** (Cqrs.Query.QueryError) %{email: ["has invalid format"]}

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

  defmodule QueryError do
    defexception [:query]

    def message(%{query: query}) do
      query
      |> Ecto.Changeset.traverse_errors(&translate_error/1)
      |> inspect()
    end

    defp translate_error({msg, opts}) do
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end
  end

  @type opts :: keyword()
  @type query :: Ecto.Query.t()
  @type filters :: keyword()

  @callback handle_create(filters(), opts()) :: query()
  @callback handle_validate(Ecto.Changeset.t(), opts()) :: Ecto.Changeset.t()
  @callback handle_execute(Ecto.Query.t(), opts()) ::
              {:ok, any()} | {:error, query()} | {:error, any()}

  alias Cqrs.{Documentation, Query}

  defmacro __using__(opts \\ []) do
    require_all_filters = Keyword.get(opts, :require_all_filters, false)

    quote location: :keep do
      Module.register_attribute(__MODULE__, :filters, accumulate: true)
      Module.register_attribute(__MODULE__, :required_filters, accumulate: true)
      Module.put_attribute(__MODULE__, :require_all_filters, unquote(require_all_filters))

      import Ecto.Query
      import Query, only: [filter: 2, filter: 3]

      @behaviour Query
      @before_compile Query

      def handle_validate(changeset, _opts), do: changeset

      defoverridable handle_validate: 2
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      Query.__introspection__()
      Query.__schema__()
      Query.__constructor__()
      Query.__execute__()

      Module.delete_attribute(__MODULE__, :filters)
      Module.delete_attribute(__MODULE__, :required_filters)
      Module.delete_attribute(__MODULE__, :require_all_filters)
    end
  end

  defmacro __introspection__ do
    quote do
      require Documentation

      @filter_docs Documentation.field_docs("Filters", @filters, @required_filters)

      def __filter_docs__, do: @filter_docs
      def __module_docs__, do: @moduledoc
      def __query__, do: String.trim_leading(to_string(__MODULE__), "Elixir.")
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
      @spec new(Query.filters(), keyword()) :: {:ok, Ecto.Query.t()} | {:error, any()}
      @spec new!(Query.filters(), keyword()) :: Ecto.Query.t()

      require Documentation

      @doc """
      Creates a new `#{__MODULE__} query.`

      #{@filter_docs}
      """
      def new(filters \\ [], opts \\ []) when is_list(opts),
        do: Query.__new__(__MODULE__, filters, @required_filters, opts)

      @doc """
      Creates a new `#{__MODULE__} query.`

      #{@filter_docs}
      """
      def new!(filters \\ [], opts \\ []) when is_list(opts),
        do: Query.__new__!(__MODULE__, filters, @required_filters, opts)
    end
  end

  defmacro __execute__ do
    quote generated: true, location: :keep do
      def execute(query, opts \\ []) do
        Query.execute(__MODULE__, query, opts)
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

      @filters {unquote(name), unquote(type), unquote(opts)}
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
      {:error, query} -> raise Cqrs.Query.QueryError, query: query
    end
  end

  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values

  def execute(mod, {:ok, query}, opts), do: mod.handle_execute(query, opts)
  def execute(_mod, {:error, query}, _opts), do: {:error, query}
  def execute(mod, %Ecto.Query{} = query, opts), do: mod.handle_execute(query, opts)
end
