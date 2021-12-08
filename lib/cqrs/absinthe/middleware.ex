defmodule Cqrs.Absinthe.Middleware do
  @moduledoc false

  alias Cqrs.Absinthe.Middleware

  def middleware(opts) do
    before_resolve = Keyword.get(opts, :before_resolve, &Middleware.passthrough/2)
    after_resolve = Keyword.get(opts, :after_resolve, &Middleware.passthrough/2)
    {before_resolve, after_resolve}
  end

  def passthrough(res, _), do: res
end
