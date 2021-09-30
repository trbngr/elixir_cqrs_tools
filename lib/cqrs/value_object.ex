defmodule Cqrs.ValueObject do
  @moduledoc """
  The `ValueObject` macro allows you to define a typed struct with validation.

  ## Options

  * `require_all_fields` (:boolean) - If `true`, all fields will be required. Defaults to `true`
  """

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
  @callback after_validate(struct()) :: struct()

  alias Cqrs.{Documentation, InvalidValuesError, ValueObject, ValueObjectError, Input}

  defmacro __using__(opts \\ []) do
    require_all_fields = Keyword.get(opts, :require_all_fields, true)
    create_jason_encoders = Application.get_env(:cqrs_tools, :create_jason_encoders, true)

    quote do
      Module.put_attribute(__MODULE__, :require_all_fields, unquote(require_all_fields))
      Module.put_attribute(__MODULE__, :create_jason_encoders, unquote(create_jason_encoders))

      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :required_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :schema_value_objects, accumulate: true)

      import ValueObject, only: :macros

      @desc nil
      @behaviour ValueObject
      @before_compile ValueObject

      @impl true
      def handle_validate(changeset, _opts), do: changeset

      @impl true
      def after_validate(object), do: object

      defoverridable handle_validate: 2, after_validate: 1
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      ValueObject.__module_docs__()
      ValueObject.__schema__()
      ValueObject.__changeset__()
      ValueObject.__introspection__()
      ValueObject.__constructor__()

      Module.delete_attribute(__MODULE__, :schema_fields)
      Module.delete_attribute(__MODULE__, :required_fields)
      Module.delete_attribute(__MODULE__, :require_all_fields)
      Module.delete_attribute(__MODULE__, :schema_value_objects)
      Module.delete_attribute(__MODULE__, :create_jason_encoders)
    end
  end

  defmacro __changeset__ do
    quote do
      def changeset(value_object \\ %__MODULE__{}, attrs)

      def changeset(value_object, %__MODULE__{} = attrs),
        do: changeset(value_object, Map.from_struct(attrs))

      def changeset(value_object, %{} = attrs) do
        fields = __MODULE__.__schema__(:fields)
        embeds = __MODULE__.__schema__(:embeds)

        changeset = Ecto.Changeset.cast(value_object, attrs, fields -- embeds)

        embeds
        |> Enum.reduce(changeset, &Ecto.Changeset.cast_embed(&2, &1))
        |> Ecto.Changeset.validate_required(@required_fields)
        |> __MODULE__.handle_validate([])
      end
    end
  end

  defmacro __schema__ do
    quote do
      use Ecto.Schema

      if @create_jason_encoders and Code.ensure_loaded?(Jason), do: @derive(Jason.Encoder)

      @primary_key false
      embedded_schema do
        Enum.map(@schema_fields, fn
          {name, :enum, opts} ->
            Ecto.Schema.field(name, Ecto.Enum, opts)

          {name, :binary_id, opts} ->
            Ecto.Schema.field(name, Ecto.UUID, opts)

          {name, type, opts} ->
            Ecto.Schema.field(name, type, opts)
        end)

        Enum.map(@schema_value_objects, fn
          {name, {:array, type}, _opts} ->
            Ecto.Schema.embeds_many(name, type)

          {name, type, _opts} ->
            Ecto.Schema.embeds_one(name, type)
        end)
      end
    end
  end

  defmacro __introspection__ do
    quote do
      @name __MODULE__ |> Module.split() |> Enum.reverse() |> hd() |> to_string()

      def __fields__, do: @schema_fields ++ @schema_value_objects
      def __required_fields__, do: @required_fields
      def __module_docs__, do: @moduledoc
      def __value_object__, do: __MODULE__
      def __name__, do: @name
    end
  end

  defmacro __module_docs__ do
    quote do
      require Documentation

      moduledoc = @moduledoc || ""
      @field_docs Documentation.field_docs("Fields", @schema_fields, @required_fields)

      Module.put_attribute(
        __MODULE__,
        :moduledoc,
        {1, moduledoc <> @field_docs}
      )
    end
  end

  defmacro __constructor__ do
    quote do
      @doc """
      Creates a new `#{__MODULE__} object.`

      #{@moduledoc}
      """
      def new(attrs \\ [], opts \\ []) when is_list(opts),
        do: ValueObject.__new__(__MODULE__, attrs, @required_fields, opts)

      @doc """
      Creates a new `#{__MODULE__} command.`

      #{@moduledoc}
      """
      def new!(attrs \\ [], opts \\ []) when is_list(opts),
        do: ValueObject.__new__!(__MODULE__, attrs, @required_fields, opts)
    end
  end

  @doc """
  Defines a value object field.

  * `:name` - any `atom`
  * `:type` - any valid [Ecto Schema](`Ecto.Schema`) type
  * `:opts` - any valid [Ecto Schema](`Ecto.Schema`) field options. Plus:

      * `:required` - `true | false`. Defaults to the `require_all_fields` option.
      * `:description` - Documentation for the field.
  """

  @spec field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro field(name, type, opts \\ []) do
    quote location: :keep do
      required = Keyword.get(unquote(opts), :required, @require_all_fields)
      if required, do: @required_fields(unquote(name))

      opts =
        unquote(opts)
        |> Keyword.put(:required, required)
        |> Keyword.update(:description, @desc, &Function.identity/1)

      # reset the @desc attr
      @desc nil

      if Cqrs.Command.__is_value_object__?(unquote(type)) do
        @schema_value_objects {unquote(name), unquote(type), opts}
      else
        @schema_fields {unquote(name), unquote(type), opts}
      end
    end
  end

  alias Ecto.Changeset

  def __init__(mod, attrs, required_fields, opts) do
    fields = mod.__schema__(:fields)
    embeds = mod.__schema__(:embeds)

    changeset =
      mod
      |> struct()
      |> Changeset.cast(attrs, fields -- embeds)

    embeds
    |> Enum.reduce(changeset, &Changeset.cast_embed(&2, &1))
    |> Changeset.validate_required(required_fields)
    |> mod.handle_validate(opts)
  end

  def __new__(mod, attrs, required_fields, opts) when is_list(opts) do
    attrs = Input.normalize_input(attrs, mod)

    mod
    |> __init__(attrs, required_fields, opts)
    |> case do
      %{valid?: false} = changeset ->
        {:error, changeset}

      %{valid?: true} = changeset ->
        attrs =
          changeset
          |> Changeset.apply_changes()
          |> mod.after_validate()
          |> Input.normalize_input(mod)

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
      {:error, errors} -> raise ValueObjectError, errors: errors
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
end
