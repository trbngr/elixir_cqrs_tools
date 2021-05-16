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
