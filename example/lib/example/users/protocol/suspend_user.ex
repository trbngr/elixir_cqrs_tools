defmodule Example.Users.Protocol.SuspendUser do
  use Cqrs.Command, dispatcher: Example.App

  @moduledoc """
  Suspends an active user.

  If the user is not active, this is a no-op.
  """

  field :id, :binary_id

  derive_event UserSuspended, with: [status: :suspended]
end
