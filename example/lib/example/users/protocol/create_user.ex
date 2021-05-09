defmodule Example.Users.Protocol.CreateUser do
  @moduledoc """
  Creates a new user.
  """
  use Cqrs.Command, dispatcher: Example.App

  field :name, :string
  field :email, :string

  field :id, :binary_id, internal: true

  derive_event UserCreated, with: [status: :active]

  @impl true
  def handle_validate(command, _opts) do
    Ecto.Changeset.validate_format(command, :email, ~r/@/)
  end

  @impl true
  def after_validate(%{email: email} = command) do
    Map.put(command, :id, UUID.uuid5(:oid, email))
  end
end
