defmodule Cqrs.Input do
  @moduledoc false

  alias Cqrs.InvalidValuesError

  def normalize_input(input, mod) do
    mod
    |> normalize(input)
    |> populate_from_sources(mod)
    |> destruct_values()
  end

  defp destruct_values(list) when is_list(list), do: Enum.map(list, &destruct_values/1)

  defp destruct_values(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_struct(key) -> {to_string(key), destruct_values(Map.from_struct(value))}
      {key, value} -> {to_string(key), value}
    end)
  end

  defp destruct_values(other), do: other

  defp normalize(_mod, values) when is_list(values), do: Enum.into(values, %{})
  defp normalize(_mod, values) when is_struct(values), do: Map.from_struct(values)
  defp normalize(_mod, values) when is_map(values), do: values
  defp normalize(mod, _other), do: raise(InvalidValuesError, module: mod)

  defp populate_from_sources(input, mod) do
    Enum.reduce(mod.__schema__(:fields), input, fn field, acc ->
      field_source = mod.__schema__(:field_source, field)
      source_value = Map.get(input, field_source)

      acc
      |> Map.delete(field_source)
      |> Map.update(field, source_value, fn
        nil -> source_value
        other -> other
      end)
    end)
  end
end
