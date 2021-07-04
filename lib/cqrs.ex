defmodule Cqrs do
  alias Cqrs.{BoundedContext, Command, DomainEvent, Query, Absinthe, Absinthe.Relay}

  @moduledoc """
  `CqrsTools` is a set of macros to let you focus on your core business and make CQRS applications easier to manage.

  ## [Commands](`#{Command}`)

  Creates commands with validation, dispatch logic, and more.

  ## [Events](`#{DomainEvent}`)

  Creates events...easily

  ## [Queries](`#{Query}`)

  Define queries with filters, validation, execution, and more.

  ## [Bounded Contexts](`#{BoundedContext}`)

  Creates proxy functions for [commands](`#{Command}`) and [events](`#{DomainEvent}`).

  ## [Absinthe Macros](`#{Absinthe}`)

  Macros to derive queries and mutations from [Queries](`#{Query}`) and [Commands](`#{Command}`), respectfully.

  ## [Absinthe Relay Macros](`#{Relay}`)

  Macros for `Absinthe.Relay`
  """
end
