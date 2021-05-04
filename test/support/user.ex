defmodule User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
  end
end
