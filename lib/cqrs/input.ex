defmodule Cqrs.Input do
  @moduledoc false

  alias Cqrs.InvalidValuesError

  def normalize_input(input, mod) do
    mod
    |> normalize(input)
    |> string_keys()
    |> destruct()
    |> populate_from_sources(mod)
  end

  defp destruct(list) when is_list(list), do: Enum.map(list, &destruct/1)

  defp destruct(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_struct(key) -> {key, destruct(Map.from_struct(value))}
      {key, value} -> {key, value}
    end)
  end

  defp destruct(other), do: other

  defp normalize(_mod, input) when is_list(input), do: Enum.into(input, %{})
  defp normalize(_mod, input) when is_struct(input), do: Map.from_struct(input)
  defp normalize(_mod, input) when is_map(input), do: input
  defp normalize(mod, _other), do: raise(InvalidValuesError, module: mod)

  defp string_keys(input) do
    for {key, value} <- input, into: %{} do
      {to_string(key), value}
    end
  end

  defp populate_from_sources(input, mod) do
    Enum.reduce(mod.__schema__(:fields), input, fn field, acc ->
      field_source = mod.__schema__(:field_source, field)
      source_value = Map.get(input, field_source)

      acc
      |> Map.delete(field_source)
      |> Map.update(to_string(field), source_value, fn
        nil -> source_value
        other -> other
      end)
    end)
  end
end
