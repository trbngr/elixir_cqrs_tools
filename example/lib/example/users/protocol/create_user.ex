defmodule Example.Users.Protocol.CreateUser do
  @moduledoc """
  Creates a new user.
  """
  use Cqrs.Command, dispatcher: Example.App

  field :id, :binary_id, internal: true

  field :name, :string, description: "The user's name"

  @desc "The user's email"
  field :email, :string

  option :metadata, :map, default: %{}, description: "User metadata"

  derive_event UserCreated, with: [status: :active]

  @impl true
  def handle_validate(command, _opts) do
    Ecto.Changeset.validate_format(command, :email, ~r/@/)
  end

  @impl true
  def after_validate(%{email: email} = command) do
    Map.put(command, :id, UUID.uuid5(:oid, email))
  end

  @impl true
  def before_dispatch(command, opts) do
    IO.inspect(Keyword.get(opts, :metadata), label: "metadata")
    {:ok, command}
  end
end
