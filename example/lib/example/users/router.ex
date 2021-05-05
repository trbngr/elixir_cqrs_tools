defmodule Example.Users.Router do
  use Commanded.Commands.Router

  alias Example.Users.UserAggregate
  alias Example.Users.Messages.{CreateUser, ReinstateUser, SuspendUser}

  dispatch [CreateUser, ReinstateUser, SuspendUser],
    to: UserAggregate,
    identity: :id,
    identity_prefix: "user-"
end
