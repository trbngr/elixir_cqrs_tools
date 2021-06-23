if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.InvalidEnumError do
    defexception [:module, :field]

    def message(%{module: module, field: field}) do
      "The field '#{module}.#{field}' is not an enum."
    end
  end

  defmodule Cqrs.Absinthe.InvalidEnumSourceError do
    defexception [:module]

    def message(%{module: module}),
      do: "#{inspect(module)} is not a Cqrs.Query, Cqrs.Command, or an Ecto.Schema"
  end

  defmodule Cqrs.Absinthe.MapTypeMappingError do
    defexception [:source, :macro, :type]

    def message(%{source: source, macro: macro, type: type}) do
      example = """
      #{macro} #{source}, :return_type,
      as: :query_name,
      arg_types: [#{IO.ANSI.format([:red, to_string(type), ": :existing_absinthe_type"])}]
      """

      """
      Missing absinthe type for the type #{source}.#{type}.

      Example:
      #{IO.ANSI.format([:blue, example])}
      """
    end
  end

  defmodule Cqrs.Absinthe.EnumTypeMappingError do
    defexception [:source, :macro, :type]

    def message(%{source: source, macro: macro, type: type}) do
      example = """
      #{macro} #{source}, :return_type,
      as: :query_name,
      arg_types: [#{IO.ANSI.format([:red, to_string(type), ": :existing_absinthe_enum_type"])}]
      """

      """
      Missing absinthe enum type for the type #{source}.#{type}.

      Example:
      #{IO.ANSI.format([:blue, example])}
      """
    end
  end
end
