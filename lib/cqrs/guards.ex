defmodule Cqrs.Guards do
  @moduledoc false
  alias Cqrs.{InvalidCommandError, InvalidQueryError, InvalidRouterError}

  def ensure_is_struct!(module) do
    unless function_exported?(module, :__struct__, 0) do
      raise "#{module} should be a valid struct."
    end
  end

  def ensure_is_command!(module) do
    _ = module.__info__(:functions)

    unless function_exported?(module, :__command__, 0) do
      raise InvalidCommandError, command: module
    end
  end

  def ensure_is_query!(module) do
    _ = module.__info__(:functions)

    unless function_exported?(module, :__query__, 0) do
      raise InvalidQueryError, query: module
    end
  end

  def ensure_is_commanded_router!(module) do
    _ = module.__info__(:functions)

    unless function_exported?(module, :__registered_commands__, 0) do
      raise InvalidRouterError, router: module
    end
  end

  def ensure_is_dispatcher!(module) do
    _ = module.__info__(:functions)

    unless function_exported?(module, :dispatch, 2) do
      raise "#{module} is required to export a dispatch/2 function."
    end
  end
end
