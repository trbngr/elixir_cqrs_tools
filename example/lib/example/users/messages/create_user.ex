defmodule Example.Users.Messages.CreateUser do
  use Cqrs.Command, dispatcher: Example.App

  field :name, :string
  field :email, :string

  field :id, :binary_id, required: false

  derive_event UserCreated, with: [status: :active]

  @impl true
  def after_validate(%{email: email} = command) do
    Map.put(command, :id, UUID.uuid5(:oid, email))
  end
end
