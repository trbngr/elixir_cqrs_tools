defmodule Cqrs.DomainEvent do
  @moduledoc """
  Defines a new domain event struct

  ## Options

  * `:from` _optional_ - a struct to derive fields from.
  * `:with` _optional_ - a list of `atom` field names to add.
  * `:drop` _optional_ - a list of `atom` field names to remove from any field derived from the struct in the `:from` option.
  * `:version` _optional_ - a version value. Defaults to `1`

  ## Example
      defmodule DeleteUser do
        use Cqrs.Command

        field :id, :integer

        def handle_dispatch(command, _opts) do
          {:ok, :no_impl}
        end
      end

      defmodule UserDeleted do
        use Cqrs.DomainEvent,
          from: DeleteUser,
          with: [:from],
          version: 2
      end

      iex> cmd = DeleteUser.new!(id: 668)
      ...> event = UserDeleted.new(cmd, from: "chris")
      ...> %{id: event.id, from: event.from, version: event.version}
      %{id: 668, from: "chris", version: 2}
  """
  alias Cqrs.{DomainEvent, Guards}

  defmacro __using__(opts) do
    create_jason_encoders = Application.get_env(:cqrs_tools, :create_jason_encoders, true)

    quote generated: true, location: :keep do
      version = Keyword.get(unquote(opts), :version, 1)
      explicit_keys = DomainEvent.explicit_keys(unquote(opts))
      inherited_keys = DomainEvent.inherit_keys(unquote(opts))

      keys =
        Keyword.merge(inherited_keys, explicit_keys, fn
          _key, nil, nil -> nil
          _key, nil, value -> value
          _key, value, nil -> value
        end)

      if unquote(create_jason_encoders) and Code.ensure_loaded?(Jason), do: @derive(Jason.Encoder)

      defstruct keys
                |> DomainEvent.drop_keys(unquote(opts))
                |> Kernel.++([{:created_at, nil}, {:version, version}])

      def new(source \\ [], attrs \\ []) do
        DomainEvent.new(__MODULE__, source, attrs)
      end
    end
  end

  @doc false
  def drop_keys(keys, opts) do
    keys_to_drop = Keyword.get(opts, :drop, []) |> List.wrap()

    Enum.reject(keys, fn
      {:__struct__, _} -> true
      {:created_at, _} -> true
      {name, _default_value} -> Enum.member?(keys_to_drop, name)
      name -> Enum.member?(keys_to_drop, name)
    end)
  end

  @doc false
  def inherit_keys(opts) do
    case Keyword.get(opts, :from) do
      nil ->
        []

      source when is_atom(source) ->
        Guards.ensure_is_struct!(source)

        source
        |> struct()
        |> Map.to_list()

      source ->
        "#{source} should be a valid struct to use with DomainEvent"
    end
  end

  @doc false
  def explicit_keys(opts) do
    opts
    |> Keyword.get(:with, [])
    |> List.wrap()
    |> Enum.map(fn
      field when is_tuple(field) -> field
      field when is_atom(field) or is_binary(field) -> {field, nil}
    end)
  end

  @doc false
  def new(module, source, attrs) when is_atom(module) do
    fields =
      source
      |> normalize()
      |> Map.merge(normalize(attrs))
      |> Map.put(:created_at, Cqrs.Clock.utc_now(module))

    struct(module, fields)
  end

  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values
  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
end
