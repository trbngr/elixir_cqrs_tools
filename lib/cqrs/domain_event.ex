defmodule Cqrs.DomainEvent do
  @moduledoc """
  Defines a new domain event struct

  ## Options

  * `:from` _optional_ - a struct to derive fields from.
  * `:with` _optional_ - a list of `atom` field names to add.
  * `:drop` _optional_ - a list of `atom` field names to remove from any field derived
  from the struct in the `:from` option.
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
    quote generated: true, location: :keep do
      version = Keyword.get(unquote(opts), :version, 1)
      inherited_keys = DomainEvent.inherit_keys(unquote(opts))
      explicit_keys = Keyword.get(unquote(opts), :with, []) |> List.wrap()
      keys_to_drop = Keyword.get(unquote(opts), :drop, []) |> List.wrap()

      if Code.ensure_loaded?(Jason), do: @derive(Jason.Encoder)

      defstruct (inherited_keys ++ explicit_keys)
                |> Enum.reject(&Enum.member?(keys_to_drop, &1))
                |> List.delete(:created_at)
                |> Kernel.++([:created_at, {:version, version}])

      def new(source \\ [], attrs \\ []) do
        DomainEvent.new(__MODULE__, source, attrs)
      end
    end
  end

  @doc false
  def inherit_keys(opts) do
    case Keyword.get(opts, :from) do
      nil ->
        []

      source when is_atom(source) ->
        Guards.ensure_is_struct!(source)
        Map.keys(source.__struct__())

      source ->
        "#{source} should be a valid struct to use with DomainEvent"
    end
  end

  @doc false
  def new(module, source, attrs) when is_atom(module) do
    fields =
      source
      |> normalize()
      |> Map.merge(normalize(attrs))
      |> Map.put(:created_at, DateTime.utc_now())

    struct(module, fields)
  end

  defp normalize(values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(values) when is_map(values), do: values
  defp normalize(values) when is_list(values), do: Enum.into(values, %{})
end
