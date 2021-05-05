defmodule Example.Users.Messages.ReinstateUser do
  use Cqrs.Command, dispatcher: Example.App

  field :id, :binary_id

  derive_event UserReinstated, with: [status: :active]
end
