defmodule Example.ReadModel.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "users" do
    field :id, :binary_id, primary_key: true
    field :name, :string
    field :email, :string
    field :status, Ecto.Enum, values: [:active, :suspended]
  end

  def changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, [:id, :name, :email, :status])
    |> validate_required([:id, :name, :email, :status])
  end
end
