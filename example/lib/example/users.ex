defmodule Example.Users do
  use Cqrs.BoundedContext

  alias Example.Users.Protocol.{CreateUser, ReinstateUser, SuspendUser}

  command CreateUser
  command SuspendUser
  command ReinstateUser

  query Example.Queries.GetUser
  query Example.Queries.ListUsers
end
