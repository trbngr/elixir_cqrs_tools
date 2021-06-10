if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Args do
    @moduledoc false
    def extract_args(fields, opts) do
      only = Keyword.get(opts, :only, [])
      except = Keyword.get(opts, :except, [])

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

        required = Keyword.get(field_opts, :required, false)
        default_value = Keyword.get(field_opts, :default)

        absinthe_opts =
          field_opts
          |> Keyword.take([:description, :deprecate, :name])
          |> Keyword.put(:default_value, default_value)

        {name, absinthe_type, required, absinthe_opts}
      end)
    end

    defp absinthe_type({name, :map, _}, opts) do
      source = Keyword.get(opts, :source)
      macro = Keyword.get(opts, :macro)

      map_type =
        get_named_arg_type_mapping(name, opts) || get_configured_type_mapping(:map) ||
          raise Cqrs.Absinthe.MapTypeMappingError, source: source, macro: macro, type: name

      quote do: unquote(map_type)
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
        get_named_arg_type_mapping(name, opts) ||
          raise Cqrs.Absinthe.EnumTypeMappingError, source: source, macro: macro, type: name

      quote do: unquote(enum_type)
    end

    defp absinthe_type({_name, :binary_id, _}, _opts), do: quote(do: :id)
    defp absinthe_type({_name, :utc_datetime, _}, _opts), do: quote(do: :datetime)
    defp absinthe_type({_name, type, _}, _opts), do: quote(do: unquote(type))

    defp get_configured_type_mapping(type) do
      :cqrs_tools
      |> Application.get_env(:absinthe, [])
      |> Keyword.get(:type_mappings, [])
      |> Keyword.get(type)
    end

    def get_named_arg_type_mapping(name, opts) do
      opts
      |> Keyword.get(:arg_types, [])
      |> Keyword.get(name)
    end
  end
end
