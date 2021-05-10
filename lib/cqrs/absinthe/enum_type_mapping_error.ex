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
