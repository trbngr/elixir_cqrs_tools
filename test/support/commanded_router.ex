defmodule CommandedRouter do
  use Commanded.Commands.Router

  dispatch([CreateUser, DeactivateUser],
    to: UserAggregate
  )
end
