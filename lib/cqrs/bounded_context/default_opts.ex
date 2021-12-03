defmodule Cqrs.BoundedContext.DefaultOpts do
  @moduledoc false
  def set(opts) do
    :cqrs_tools
    |> Application.get_env(:bounded_context, [])
    |> Keyword.get(:default_opts, [])
    |> Keyword.merge(opts)
  end
end
