defmodule Cqrs.Absinthe.Metadata do
  def merge(%{context: context}, opts) when is_list(context) do
    context
    |> Enum.into(%{})
    |> merge(opts)
  end

  def merge(%{context: context}, opts) when is_map(context) do
    existing_metadata =
      opts
      |> Keyword.get(:metadata, %{})
      |> Enum.into(%{})

    context = Map.drop(context, [:__absinthe_plug__, :pubsub])
    metadata = Map.merge(context, existing_metadata)

    Keyword.put(opts, :metadata, metadata)
  end

  def merge(_, opts), do: opts
end
