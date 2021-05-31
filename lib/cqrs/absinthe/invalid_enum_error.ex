defmodule Cqrs.Absinthe.InvalidEnumError do
  defexception [:module, :field]

  def message(%{module: module, field: field}) do
    "The field '#{module}.#{field}' is not an enum."
  end
end
