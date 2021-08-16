defmodule Cqrs.Absinthe.Middleware do
  @moduledoc false

  alias Cqrs.Absinthe.Middleware
  alias Cqrs.Absinthe.InvalidMiddlewareFunction

  defmacro before_resolve(module, opts) do
    quote do
      alias Cqrs.Absinthe.Middleware
      Middleware.ensure_middelware_function!(unquote(module), unquote(opts), :before_resolve)

      middleware fn res, config ->
        fun = Middleware.middelware_function(unquote(opts), :before_resolve)
        fun.(res, config)
      end
    end
  end

  defmacro after_resolve(module, opts) do
    quote do
      alias Cqrs.Absinthe.Middleware
      Middleware.ensure_middelware_function!(unquote(module), unquote(opts), :after_resolve)

      middleware fn res, config ->
        fun = Middleware.middelware_function(unquote(opts), :after_resolve)
        fun.(res, config)
      end
    end
  end

  def passthrough(res, _), do: res

  def ensure_middelware_function!(module, opts, position) do
    case middelware_function(opts, position) do
      fun when is_function(fun, 2) -> fun
      _ -> raise InvalidMiddlewareFunction, module: module, position: position
    end
  end

  def middelware_function(opts, position) do
    Keyword.get(opts, position, &Middleware.passthrough/2)
  end
end
