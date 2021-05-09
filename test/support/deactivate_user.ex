defmodule DeactivateUser do
  use Cqrs.Command, dispatcher: CommandedApplication

  field :id, :binary_id

  derive_event(UserDeactivated)
end
