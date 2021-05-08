defmodule Example.Users do
  use Cqrs.BoundedContext
  use Cqrs.BoundedContext.Commanded

  import_commands Example.Users.Router

  query Example.Queries.GetUser
  query Example.Queries.ListUsers
end
