defmodule Cqrs do
  alias Cqrs.{BoundedContext, Command, DomainEvent, Query}

  @moduledoc """
  `CqrsTools` is a set of macros to make CQRS applications easy to manager.

  ## [Bounded Contexts](`#{BoundedContext}`)

  Creates proxy functions for [commands](`#{Command}`) and [events](`#{DomainEvent}`).

  ## [Commands](`#{Command}`)

  Creates commands with validation, dispatch logic, and more.

  ## [Events](`#{DomainEvent}`)

  Creates events...easily

  ## [Queries](`#{Query}`)

  Define queries with filters, validation, execution, and more.
  """
end
