defmodule AbsintheJsonType do
  use Absinthe.Schema.Notation
  alias Absinthe.Blueprint.Input.{Null, String}

  scalar :json, name: "Json" do
    serialize &encode/1
    parse &decode/1
  end

  defp decode(%String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Null{}), do: {:ok, nil}
  defp decode(_), do: :error

  defp encode(value), do: value
end
