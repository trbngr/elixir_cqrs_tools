defmodule Example.Users.Messages.SuspendUser do
  use Cqrs.Command, dispatcher: Example.App

  field :id, :binary_id

  derive_event UserSuspended, with: [status: :suspended]
end
