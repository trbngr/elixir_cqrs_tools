defmodule CreateUser do
  use Cqrs.Command

  field :email, :string
  field :name, :string
  field :id, :binary_id, internal: true

  derive_event UserCreated

  @impl true
  def handle_validate(command, _opts) do
    Ecto.Changeset.validate_format(command, :email, ~r/@/)
  end

  @impl true
  def after_validate(%{email: email} = command) do
    Map.put(command, :id, UUID.uuid5(:oid, email))
  end

  @impl true
  def handle_dispatch(_command, _opts) do
    {:ok, :dispatched}
  end
end
