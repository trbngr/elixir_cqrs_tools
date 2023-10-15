defmodule Cqrs.EctoUtils do
  @moduledoc false

  def sanitize_opts(opts) do
    opts
    |> Keyword.delete(:required)
    |> Keyword.delete(:description)
    |> Keyword.delete(:internal)
  end
end
