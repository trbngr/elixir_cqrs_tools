defmodule Cqrs.Absinthe.Enum do
  alias Cqrs.Absinthe.InvalidEnumError

  def create_enum(command_or_query_module, field_name, enum_name) do
    values =
      case find_enum(command_or_query_module, field_name) do
        nil -> raise InvalidEnumError, module: command_or_query_module, field: field_name
        values -> Enum.map(values, fn enum_value -> quote do: value(unquote(enum_value)) end)
      end

    quote do
      enum unquote(enum_name) do
        (unquote_splicing(values))
      end
    end
  end

  defp find_enum(module, field_name) do
    fields =
      if function_exported?(module, :__command__, 0),
        do: module.__fields__(),
        else: module.__filters__()

    case Enum.find(fields, &match?({^field_name, :enum, _opts}, &1)) do
      nil -> nil
      {_name, _enum, opts} -> Keyword.get(opts, :values)
    end
  end
end
