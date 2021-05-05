defmodule Example.Users do
  use Cqrs.BoundedContext
  import Cqrs.BoundedContext

  import_commands Example.Users.Router

  query Example.Queries.GetUser
  query Example.Queries.ListUsers
end
