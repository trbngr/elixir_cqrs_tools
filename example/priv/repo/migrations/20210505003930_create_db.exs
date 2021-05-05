defmodule Example.Repo.Migrations.CreateDb do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :status, :string
    end
  end
end
