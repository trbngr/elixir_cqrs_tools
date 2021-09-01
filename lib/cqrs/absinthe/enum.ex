if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Enum do
    @moduledoc false
    alias Cqrs.Absinthe.InvalidEnumError

    def create_enum(enum_name, source_module, field_name) do
      values =
        case find_enum_values(source_module, field_name) do
          [] ->
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
        {:parameterized, Ecto.Enum, opts} -> read_enum_values(opts)
        {:array, {:parameterized, Ecto.Enum, opts}} -> read_enum_values(opts)
        _ -> []
      end
    end

    defp read_enum_values(opts) do
      from_mappings =
        opts
        |> Map.get(:mappings, [])
        |> Keyword.keys()

      from_values = Map.get(opts, :values, [])

      from_mappings ++ from_values
    end
  end
end
