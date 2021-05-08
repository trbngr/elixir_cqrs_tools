defmodule Cqrs do
  alias Cqrs.{BoundedContext, Command, DomainEvent, Query, Absinthe, Absinthe.Relay}

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

  ## [Absinthe](`#{Absinthe}`) convenience macros

  Macros to derive queries and mutations from [Queries](`#{Query}`) and [Commands](`#{Command}`), respectfully.

  ## [Absinthe Relay](`#{Relay}`) convenience macros

  Macros for `Absinthe.Relay`
  """

end
