defmodule Cqrs.Absinthe.Metadata do
  def merge(%{context: context}, opts) do
    existing_metadata =
      opts
      |> Keyword.get(:metadata, %{})
      |> Enum.into(%{})

    metadata =
      context
      |> Map.drop([:__absinthe_plug__, :pubsub])
      |> Enum.into(%{})

    Keyword.put(opts, :metadata, Map.merge(metadata, existing_metadata))
  end
end
