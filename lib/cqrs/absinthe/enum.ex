if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Enum do
    alias Cqrs.Absinthe.InvalidEnumError

    def create_enum(enum_name, source_module, field_name) do
      values =
        case find_enum_values(source_module, field_name) do
          nil ->
            raise InvalidEnumError, module: source_module, field: field_name

          values ->
            Enum.map(values, fn enum_value -> quote do: value(unquote(enum_value)) end)
        end

      quote do
        enum unquote(enum_name) do
          (unquote_splicing(values))
        end
      end
    end

    defp find_enum_values(module, field_name) do
      case module.__schema__(:type, field_name) do
        {:parameterized, Ecto.Enum, opts} -> Map.get(opts, :values)
        {:array, {:parameterized, Ecto.Enum, opts}} -> Map.get(opts, :values)
        _ -> nil
      end
    end
  end
end
