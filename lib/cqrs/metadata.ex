defmodule Cqrs.Metadata do
  @moduledoc false
  @callback get_metadata() :: map()

  def get_metadata, do: adapter().get_metadata()

  def put_default_metadata(opts) do
    metadata = get_metadata()
    # |> IO.inspect(label: "default metadata")

    Keyword.update(opts, :metadata, metadata, fn existing_metadata ->
      # existing_metadata |> IO.inspect(label: "existing_metadata")

      Map.merge(metadata, existing_metadata)
      # |> IO.inspect(label: "metadata")
    end)
  end

  defp adapter do
    Application.get_env(:cqrs_tools, :metadata, Cqrs.Metadata.DefaultMetadata)
  end
end
