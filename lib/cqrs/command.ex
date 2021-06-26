defmodule Cqrs.Command do
  alias Cqrs.{Command, CommandError, Documentation, DomainEvent, Guards, Options}

  @moduledoc """
  The `Command` macro allows you to define a command that encapsulates a struct definition,
  data validation, dependency validation, and dispatching of the command.

  ## Options

  * `require_all_fields` - If `true`, all fields will be required. Defaults to `true`
  * `dispatcher` - A module that defines a `dispatch/2`.

  ## Examples

      defmodule CreateUser do
        use Cqrs.Command

        field :email, :string
        field :name, :string

        internal_field :id, :binary_id

        @impl true
        def handle_validate(command, _opts) do
          Ecto.Changeset.validate_format(command, :email, ~r/@/)
        end

        @impl true
        def after_validate(%{email: email} = command) do
          Map.put(command, :id, UUID.uuid5(:oid, email))
        end

        @impl true
        def handle_dispatch(_command, _opts) do
          {:ok, :dispatched}
        end
      end

  ### Creation

      iex> {:error, errors} = CreateUser.new()
      ...> errors
      %{email: [\"can't be blank\"], name: [\"can't be blank\"]}

      iex> {:ok, %CreateUser{email: email, name: name, id: id}} = CreateUser.new(email: "chris@example.com", name: "chris")
      ...> %{email: email, name: name, id: id}
      %{email: \"chris@example.com\", id: \"052c1984-74c9-522f-858f-f04f1d4cc786\", name: \"chris\"}

      iex> %CreateUser{id: "052c1984-74c9-522f-858f-f04f1d4cc786"} = CreateUser.new!(email: "chris@example.com", name: "chris")


  ### Dispatching

      iex> {:error, {:invalid_command, errors}} =
      ...> CreateUser.new(name: "chris", email: "wrong")
      ...> |> CreateUser.dispatch()
      ...> errors
      %{email: ["has invalid format"]}

      iex> CreateUser.new(name: "chris", email: "chris@example.com")
      ...> |> CreateUser.dispatch()
      {:ok, :dispatched}

  ## Event derivation

  You can derive [events](`Cqrs.DomainEvent`) directly from a command.

  see `derive_event/2`

      defmodule DeactivateUser do
        use Cqrs.Command

        field :id, :binary_id

        derive_event UserDeactivated
      end

  ## Usage with `Commanded`

      defmodule Commanded.Application do
        use Commanded.Application,
          otp_app: :my_app,
          default_dispatch_opts: [
            consistency: :strong,
            returning: :execution_result
          ],
          event_store: [
            adapter: Commanded.EventStore.Adapters.EventStore,
            event_store: MyApp.EventStore
          ]
      end

      defmodule DeactivateUser do
        use Cqrs.Command, dispatcher: Commanded.Application

        field :id, :binary_id

        derive_event UserDeactivated
      end

      iex> {:ok, event} = DeactivateUser.new(id: "052c1984-74c9-522f-858f-f04f1d4cc786")
      ...> |> DeactivateUser.dispatch()
      ...>  %{id: event.id, version: event.version}
      %{id: "052c1984-74c9-522f-858f-f04f1d4cc786", version: 1}

  """
  @type command :: struct()

  @doc """
  Allows one to define any custom data validation aside from casting and requiring fields.

  This callback is optional.

  Invoked when the `new()` or `new!()` function is called.
  """
  @callback handle_validate(Ecto.Changeset.t(), keyword()) :: Ecto.Changeset.t()

  @doc """
  Allows one to modify the fully validated command. The changes to the command are validated again after this callback.

  This callback is optional.

  Invoked after the `handle_validate/2` callback is called.
  """
  @callback after_validate(command()) :: command()

  @doc """
  This callback is intended to be used as a last chance to do any validation that performs IO.

  This callback is optional.

  Invoked before `handle_dispatch/2`.
  """
  @callback before_dispatch(command(), keyword()) :: {:ok, command()} | {:error, any()}

  @doc """
  This callback is intended to be used to run the fully validated command.

  This callback is required.
  """
  @callback handle_dispatch(command(), keyword()) :: any()

  defmacro __using__(opts \\ []) do
    require_all_fields = Keyword.get(opts, :require_all_fields, true)
    create_jason_encoders = Application.get_env(:cqrs_tools, :create_jason_encoders, true)

    quote location: :keep do
      Module.put_attribute(__MODULE__, :require_all_fields, unquote(require_all_fields))
      Module.put_attribute(__MODULE__, :dispatcher, Keyword.get(unquote(opts), :dispatcher))
      Module.put_attribute(__MODULE__, :create_jason_encoders, unquote(create_jason_encoders))

      Module.register_attribute(__MODULE__, :events, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: true)
      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :required_fields, accumulate: true)

      require Cqrs.Options

      import Command,
        only: [field: 2, field: 3, derive_event: 1, derive_event: 2, internal_field: 2, internal_field: 3, option: 3]

      @options Cqrs.Options.tag_option()

      @desc nil
      @behaviour Command
      @before_compile Command
      @after_compile Command

      @impl true
      def handle_validate(command, _opts), do: command

      @impl true
      def after_validate(command), do: command

      @impl true
      def before_dispatch(command, _opts), do: {:ok, command}

      defoverridable handle_validate: 2, before_dispatch: 2, after_validate: 1
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      Command.__module_docs__()
      Command.__schema__()
      Command.__introspection__()
      Command.__constructor__()
      Command.__dispatch__()
      Command.__create_events__(__ENV__, @events, @schema_fields)

      Module.delete_attribute(__MODULE__, :events)
      Module.delete_attribute(__MODULE__, :options)
      Module.delete_attribute(__MODULE__, :field_docs)
      Module.delete_attribute(__MODULE__, :option_docs)
      Module.delete_attribute(__MODULE__, :schema_fields)
      Module.delete_attribute(__MODULE__, :required_fields)
      Module.delete_attribute(__MODULE__, :require_all_fields)
      Module.delete_attribute(__MODULE__, :create_jason_encoders)
    end
  end

  defmacro __after_compile__(_env, _bytecode) do
    quote location: :keep do
      if @dispatcher, do: Guards.ensure_is_dispatcher!(@dispatcher)
    end
  end

  defmacro __schema__ do
    quote generated: true, location: :keep do
      use Ecto.Schema

      if @create_jason_encoders and Code.ensure_loaded?(Jason), do: @derive(Jason.Encoder)

      @primary_key false
      embedded_schema do
        Ecto.Schema.field(:created_at, :utc_datetime)

        Enum.map(@schema_fields, fn
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

  defmacro __introspection__ do
    quote do
      @name __MODULE__ |> Module.split() |> Enum.reverse() |> hd() |> to_string()

      def __fields__, do: @schema_fields
      def __required_fields__, do: @required_fields
      def __module_docs__, do: @moduledoc
      def __command__, do: __MODULE__
      def __name__, do: @name
    end
  end

  defmacro __module_docs__ do
    quote do
      require Documentation

      moduledoc = @moduledoc || ""
      @field_docs Documentation.field_docs("Fields", @schema_fields, @required_fields)
      @option_docs Documentation.option_docs(@options)

      Module.put_attribute(
        __MODULE__,
        :moduledoc,
        {1, moduledoc <> @field_docs <> "\n" <> @option_docs}
      )
    end
  end

  defmacro __constructor__ do
    quote generated: true, location: :keep do
      @default_opts Cqrs.Options.defaults()
      defp get_opts(opts), do: Keyword.merge(@default_opts, opts)

      # @spec new(maybe_improper_list() | map(), maybe_improper_list()) :: struct()
      # @spec new!(maybe_improper_list() | map(), maybe_improper_list()) :: %__MODULE__{}

      @doc """
      Creates a new `#{__MODULE__} command.`

      #{@moduledoc}
      """
      def new(attrs \\ [], opts \\ []) when is_list(opts),
        do: Command.__new__(__MODULE__, attrs, @required_fields, get_opts(opts))

      @doc """
      Creates a new `#{__MODULE__} command.`

      #{@moduledoc}
      """
      def new!(attrs \\ [], opts \\ []) when is_list(opts),
        do: Command.__new__!(__MODULE__, attrs, @required_fields, get_opts(opts))
    end
  end

  defmacro __dispatch__ do
    quote location: :keep do
      def dispatch(command, opts \\ [])

      def dispatch(%__MODULE__{} = command, opts) do
        Command.__do_dispatch__(__MODULE__, command, get_opts(opts))
      end

      def dispatch({:ok, %__MODULE__{} = command}, opts) do
        Command.__do_dispatch__(__MODULE__, command, get_opts(opts))
      end

      def dispatch({:error, errors}, _opts) do
        {:error, {:invalid_command, errors}}
      end

      if @dispatcher do
        @impl true
        def handle_dispatch(%__MODULE__{} = cmd, opts) do
          @dispatcher.dispatch(cmd, opts)
        end
      end
    end
  end

  def __create_events__(env, events, fields) do
    command_fields = Enum.map(fields, &elem(&1, 0))

    create_event = fn {name, opts, {file, line}} ->
      options =
        Keyword.update(opts, :with, command_fields, fn fields ->
          fields
          |> List.wrap()
          |> Kernel.++(command_fields)
          |> Enum.uniq()
        end)

      domain_event =
        quote do
          use DomainEvent, unquote(options)
        end

      env =
        env
        |> Map.put(:file, file)
        |> Map.put(:line, line)

      Module.create(name, domain_event, env)
    end

    Enum.map(events, create_event)
  end

  @doc """
  Defines a command field.

  * `:name` - any `atom`
  * `:type` - any valid [Ecto Schema](`Ecto.Schema`) type
  * `:opts` - any valid [Ecto Schema](`Ecto.Schema`) field options. Plus:

      * `:required` - `true | false`. Defaults to the `require_all_fields` option.
      * `:internal` - `true | false`. If `true`, this field is meant to be used internally. If `true`, the required option will be set to `false` and the field will be hidden from documentation.
      * `:description` - Documentation for the field.
  """

  @spec field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro field(name, type, opts \\ []) do
    quote location: :keep do
      required =
        case Keyword.get(unquote(opts), :internal, false) do
          true ->
            false

          false ->
            required = Keyword.get(unquote(opts), :required, @require_all_fields)
            if required, do: @required_fields(unquote(name))
            required
        end

      opts =
        unquote(opts)
        |> Keyword.put(:required, required)
        |> Keyword.update(:description, @desc, &Function.identity/1)

      # reset the @desc attr
      @desc nil

      @schema_fields {unquote(name), unquote(type), opts}
    end
  end

  @doc """
  The same as `field/3` but sets the option `internal` to `true`.

  This helps with readability of commands with a large number of fields.
  """
  @spec internal_field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro internal_field(name, type, opts \\ []) do
    quote do
      field(unquote(name), unquote(type), Keyword.put(unquote(opts), :internal, true))
    end
  end

  @doc """
  Describes a supported option for this command.

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

  @doc """
  Generates an [event](`Cqrs.DomainEvent`) based on the fields defined in the [command](`Cqrs.Command`).

  Accepts all the options that [DomainEvent](`Cqrs.DomainEvent`) accepts.
  """
  defmacro derive_event(name, opts \\ []) do
    quote do
      [_command_name | namespace] =
        __MODULE__
        |> Module.split()
        |> Enum.reverse()

      namespace =
        namespace
        |> Enum.reverse()
        |> Module.concat()

      name = Module.concat(namespace, unquote(name))
      @events {name, unquote(opts), {__ENV__.file, __ENV__.line}}
    end
  end

  alias Ecto.Changeset

  def __init__(mod, attrs, required_fields, opts) do
    fields = mod.__schema__(:fields)

    struct(mod)
    |> Changeset.cast(normalize(attrs), fields)
    |> Changeset.validate_required(required_fields)
    |> mod.handle_validate(opts)
  end

  def __new__(mod, attrs, required_fields, opts) when is_list(opts) do
    mod
    |> __init__(attrs, required_fields, opts)
    |> Changeset.put_change(:created_at, Cqrs.Clock.utc_now())
    |> case do
      %{valid?: false} = changeset ->
        {:error, changeset}

      %{valid?: true} = changeset ->
        attrs =
          changeset
          |> Changeset.apply_changes()
          |> mod.after_validate()

        changeset2 = __init__(mod, attrs, required_fields, opts)

        changeset
        |> Changeset.merge(changeset2)
        |> Changeset.apply_action(:create)
    end
    |> case do
      {:ok, command} -> {:ok, command}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def __new__!(mod, attrs, required_fields, opts \\ []) when is_list(opts) do
    case __new__(mod, attrs, required_fields, opts) do
      {:ok, command} -> command
      {:error, errors} -> raise CommandError, errors: errors
    end
  end

  defp format_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values

  def __do_dispatch__(mod, %{__struct__: mod} = command, opts) do
    run_dispatch = fn command ->
      tag? = Keyword.get(opts, :tag?)

      command
      |> mod.handle_dispatch(opts)
      |> tag_result(tag?)
    end

    case mod.before_dispatch(command, opts) do
      {:error, error} -> {:error, error}
      {:ok, command} -> run_dispatch.(command)
      %{__struct__: ^mod} -> run_dispatch.(command)
    end
  end

  defp tag_result({:ok, result}, true), do: {:ok, result}
  defp tag_result({:error, result}, true), do: {:error, result}
  defp tag_result(result, true), do: {:ok, result}
  defp tag_result(result, _), do: result
end
