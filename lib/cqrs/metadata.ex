defmodule Cqrs.Metadata do
  @callback get_metadata() :: map()

  def get_metadata, do: adapter().get_metadata()

  def put_default_metadata(opts) do
    metadata = get_metadata()

    Keyword.update(opts, :metadata, metadata, fn existing_metadata ->
      Map.merge(metadata, existing_metadata)
    end)
  end

  defp adapter do
    Application.get_env(:cqrs_tools, :metadata, Cqrs.Metadata.DefaultMetadata)
  end
end
