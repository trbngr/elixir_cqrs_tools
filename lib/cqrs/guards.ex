defmodule Cqrs.Guards do
  @moduledoc false
  alias Cqrs.{
    InvalidCommandError,
    InvalidDispatcherError,
    InvalidQueryError,
    InvalidRouterError
  }

  def ensure_is_struct!(module) do
    unless exports_function?(module, :__struct__, 0) do
      raise "#{module |> Module.split() |> Enum.join(".")} should be a valid struct."
    end
  end

  def ensure_is_command!(module) do
    unless exports_function?(module, :__command__, 0) do
      raise InvalidCommandError, command: module
    end
  end

  def ensure_is_query!(module) do
    unless exports_function?(module, :__query__, 0) do
      raise InvalidQueryError, query: module
    end
  end

  def ensure_is_commanded_router!(module) do
    unless exports_function?(module, :__registered_commands__, 0) do
      raise InvalidRouterError, router: module
    end
  end

  def ensure_is_dispatcher!(module) do
    unless exports_function?(module, :dispatch, 2) do
      raise InvalidDispatcherError, dispatcher: module
    end
  end

  def exports_function?(module, fun, arity) do
    case Code.ensure_compiled(module) do
      {:module, _} -> function_exported?(module, fun, arity)
      _ -> false
    end
  end
end
