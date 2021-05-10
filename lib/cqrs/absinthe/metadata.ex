if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Metadata do
    @moduledoc false
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

      context = Map.take(context, metadata_keys())
      metadata = Map.merge(context, existing_metadata)

      Keyword.put(opts, :metadata, metadata)
    end

    def merge(_, opts), do: opts

    defp metadata_keys do
      :cqrs_tools
      |> Application.get_env(:absinthe, [])
      |> Keyword.get(:context_metadata_keys, [])
    end
  end
end
