defmodule Cqrs.Command do
  alias Cqrs.Command.{CommandState, CommandError}
  alias Cqrs.{Command, Documentation, DomainEvent}

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
        field :id, :binary_id, required: false

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

      iex> CreateUser.new()
      #CreateUser<errors: %{email: [\"can't be blank\"], name: [\"can't be blank\"]}>

      iex> CreateUser.new(email: "chris@example.com", name: "chris")
      #CreateUser<%{email: \"chris@example.com\", id: \"052c1984-74c9-522f-858f-f04f1d4cc786\", name: \"chris\"}>

      iex> %{id: "052c1984-74c9-522f-858f-f04f1d4cc786"} = CreateUser.new!(email: "chris@example.com", name: "chris")


  ### Dispatching

      iex> {:error, {:invalid_command, state}} =
      ...> CreateUser.new(name: "chris", email: "wrong")
      ...> |> CreateUser.dispatch()
      ...> state.errors
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
  @callback handle_dispatch(command(), keyword()) :: {:ok, any} | {:error, any()}

  defmacro __using__(opts \\ []) do
    require_all_fields = Keyword.get(opts, :require_all_fields, true)

    quote location: :keep do
      Module.register_attribute(__MODULE__, :events, accumulate: true)
      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :required_fields, accumulate: true)
      Module.put_attribute(__MODULE__, :require_all_fields, unquote(require_all_fields))
      Module.put_attribute(__MODULE__, :dispatcher, Keyword.get(unquote(opts), :dispatcher))

      import Command, only: [field: 2, field: 3, derive_event: 1, derive_event: 2]

      @behaviour Command
      @before_compile Command

      def handle_validate(command, _opts), do: command
      def after_validate(command), do: command
      def before_dispatch(command, _opts), do: {:ok, command}

      defoverridable handle_validate: 2, before_dispatch: 2, after_validate: 1
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      Command.__schema__()
      Command.__introspection__()
      Command.__constructor__()
      Command.__dispatch__()
      Command.__events__()

      Module.delete_attribute(__MODULE__, :events)
      Module.delete_attribute(__MODULE__, :dispatcher)
      Module.delete_attribute(__MODULE__, :schema_fields)
      Module.delete_attribute(__MODULE__, :required_fields)
      Module.delete_attribute(__MODULE__, :require_all_fields)
    end
  end

  defmacro __schema__ do
    quote location: :keep do
      use Ecto.Schema

      if Code.ensure_loaded?(Jason), do: @derive(Jason.Encoder)
      @primary_key false
      embedded_schema do
        Ecto.Schema.field(:created_at, :utc_datetime)

        Enum.map(@schema_fields, fn
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
      require Documentation

      @field_docs Documentation.field_docs("Fields", @schema_fields, @required_fields)

      def __field_docs__, do: @field_docs
      def __module_docs__, do: @moduledoc
      def __command__, do: String.trim_leading(to_string(__MODULE__), "Elixir.")
    end
  end

  defmacro __constructor__ do
    quote generated: true, location: :keep do
      # @spec new(maybe_improper_list() | map(), maybe_improper_list()) :: CommandState.t()
      # @spec new!(maybe_improper_list() | map(), maybe_improper_list()) :: %__MODULE__{}

      @doc """
      Creates a new `#{__MODULE__} command.`

      #{@field_docs}
      """
      def new(attrs \\ [], opts \\ []) when is_list(opts),
        do: Command.__new__(__MODULE__, attrs, @required_fields, opts)

      @doc """
      Creates a new `#{__MODULE__} command.`

      #{@field_docs}
      """
      def new!(attrs \\ [], opts \\ []) when is_list(opts),
        do: Command.__new__!(__MODULE__, attrs, @required_fields, opts)
    end
  end

  defmacro __dispatch__ do
    quote location: :keep do
      def dispatch(command, opts \\ []) do
        Command.__do_dispatch__(__MODULE__, command, opts)
      end

      if @dispatcher do
        # This appears to ensure the dispatcher module has been completly compiled
        # before checking for the dispatch function
        _ = @dispatcher.__info__(:functions)

        unless function_exported?(@dispatcher, :dispatch, 2) do
          raise "#{@dispatcher} is required to export a dispatch/2 function."
        end

        def handle_dispatch(%__MODULE__{} = cmd, opts) do
          @dispatcher.dispatch(cmd, opts)
        end
      end
    end
  end

  defmacro __events__ do
    quote location: :keep do
      command_fields = Enum.map(@schema_fields, &elem(&1, 0))

      Enum.map(@events, fn {name, opts} ->
        options =
          Keyword.update(opts, :with, command_fields, fn fields ->
            fields
            |> List.wrap()
            |> Kernel.++(command_fields)
            |> Enum.uniq()
          end)

        defmodule name do
          use DomainEvent, options
        end
      end)
    end
  end

  @doc """
  Defines a command field.

  * `:name` - any `atom`
  * `:type` - any valid [Ecto Schema](`Ecto.Schema`) type
  * `:opts` - any valid [Ecto Schema](`Ecto.Schema`) field options. Plus:

      * `:required` - `true | false`. Defaults to the `require_all_fields` option.
      * `:internal` - `true | false`. If `true`, this field is meant to be used internally and will be hidden from documentation.
      * `:description` - Documentation for the field.
  """

  @spec field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro field(name, type, opts \\ []) do
    quote location: :keep do
      required = Keyword.get(unquote(opts), :required, @require_all_fields)
      if required, do: @required_fields(unquote(name))

      @schema_fields {unquote(name), unquote(Macro.escape(type)), unquote(opts)}
    end
  end

  @doc """
  Generates an [event](`Cqrs.DomainEvent`) based on the fields defined in the [command](`Cqrs.Command`).

  Accepts all the options that [DomainEvent](`Cqrs.DomainEvent`) accepts.
  """
  defmacro derive_event(name, opts \\ []) do
    quote location: :keep do
      [_command_name | namespace] =
        __MODULE__
        |> Module.split()
        |> Enum.reverse()

      namespace =
        namespace
        |> Enum.reverse()
        |> Module.concat()

      name = Module.concat(namespace, unquote(name))
      @events {name, unquote(opts)}
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
    |> Changeset.put_change(:created_at, DateTime.utc_now())
    |> CommandState.new()
    |> case do
      %{valid?: true} = state ->
        attrs =
          state
          |> CommandState.apply_changes()
          |> mod.after_validate()

        mod
        |> __init__(attrs, required_fields, opts)
        |> CommandState.merge(state)

      state ->
        state
    end
  end

  def __new__!(mod, attrs, required_fields, opts \\ []) when is_list(opts) do
    case __new__(mod, attrs, required_fields, opts) |> CommandState.apply() do
      {:ok, command} -> command
      {:error, command} -> raise CommandError, command: command
    end
  end

  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values

  def __do_dispatch__(mod, %CommandState{changeset: changeset} = state, opts) do
    case changeset do
      %{valid?: false} ->
        {:error, {:invalid_command, state}}

      _ ->
        command = Ecto.Changeset.apply_changes(changeset)
        __do_dispatch__(mod, command, opts)
    end
  end

  def __do_dispatch__(mod, command, opts) do
    with {:ok, command} <- mod.before_dispatch(command, opts) do
      mod.handle_dispatch(command, opts)
    end
  end
end
