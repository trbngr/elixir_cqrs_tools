defmodule Example.Users.Messages.ReinstateUser do
  use Cqrs.Command, dispatcher: Example.App

  @moduledoc """
  Reinstates a suspended user.

  If the user is not suspended, this is a no-op.
  """

  field :id, :binary_id

  derive_event UserReinstated, with: [status: :active]
end
