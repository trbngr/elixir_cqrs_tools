if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.DefaultOpts do
    @moduledoc false
    def set(opts) do
      :cqrs_tools
      |> Application.get_env(:absinthe, [])
      |> Keyword.get(:default_opts, [])
      |> Keyword.merge(opts)
    end
  end
end
