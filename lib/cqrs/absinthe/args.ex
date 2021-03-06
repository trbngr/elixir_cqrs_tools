if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Args do
    @moduledoc false
    def extract_args(fields, opts) do
      only = Keyword.get(opts, :only, [])
      except = Keyword.get(opts, :except, [])
      required = Keyword.get(opts, :required, [])

      fields =
        case {only, except} do
          {[], []} -> fields
          {[], except} -> Enum.reject(fields, &Enum.member?(except, elem(&1, 0)))
          {only, []} -> Enum.filter(fields, &Enum.member?(only, elem(&1, 0)))
          _ -> raise "You can only specify :only or :except"
        end

      fields
      |> Enum.reject(fn {_name, _type, opts} -> Keyword.get(opts, :internal, false) == true end)
      |> Enum.map(fn field ->
        {name, _type, field_opts} = field
        absinthe_type = absinthe_type(field, opts)

        explicitly_required = Enum.member?(required, name)
        required = explicitly_required || Keyword.get(field_opts, :required, false)

        default_value = Keyword.get(field_opts, :default) |> Macro.escape()

        absinthe_opts =
          field_opts
          |> Keyword.take([:description, :deprecate, :name])
          |> Keyword.put(:default_value, default_value)

        {absinthe_type, absinthe_type_opts} =
          case absinthe_type do
            {absinthe_type, opts} -> {absinthe_type, opts}
            absinthe_type -> {absinthe_type, []}
          end

        {name, absinthe_type, required, Keyword.merge(absinthe_opts, absinthe_type_opts)}
      end)
    end

    defp absinthe_type({name, :map, _}, opts) do
      source = Keyword.get(opts, :source)
      macro = Keyword.get(opts, :macro)

      option_configured_type_mapping(name, opts) || app_configured_type_mapping(:map) ||
        raise Cqrs.Absinthe.MapTypeMappingError, source: source, macro: macro, type: name
    end

    defp absinthe_type({name, {:array, type}, _}, opts) do
      type = absinthe_type({name, type, nil}, opts)
      quote do: list_of(unquote(type))
    end

    defp absinthe_type({name, Ecto.Enum, field_opts}, opts) do
      absinthe_type({name, :enum, field_opts}, opts)
    end

    defp absinthe_type({name, :enum, _}, opts) do
      source = Keyword.get(opts, :source)
      macro = Keyword.get(opts, :macro)

      enum_type =
        option_configured_type_mapping(name, opts) ||
          raise Cqrs.Absinthe.EnumTypeMappingError, source: source, macro: macro, type: name

      quote do: unquote(enum_type)
    end

    defp absinthe_type({_name, :binary_id, _}, _opts), do: quote(do: :id)
    defp absinthe_type({_name, :utc_datetime, _}, _opts), do: quote(do: :datetime)

    defp absinthe_type({name, type, _}, opts) do
      type =
        option_configured_type_mapping(name, opts) ||
          app_configured_type_mapping(type) ||
          type

      quote do: unquote(type)
    end

    defp app_configured_type_mapping(type) do
      :cqrs_tools
      |> Application.get_env(:absinthe, [])
      |> Keyword.get(:type_mappings, [])
      |> Keyword.get(type)
    end

    def option_configured_type_mapping(name, opts) do
      opts
      |> Keyword.get(:arg_types, [])
      |> Keyword.get(name)
    end
  end
end
