defmodule Example.ReadModel.UserProjector do
  use Commanded.Event.Handler,
    application: Example.App,
    name: "user_projector-v1",
    consistency: :strong

  alias Example.{Repo, Users, ReadModel.User}
  alias Example.Users.Messages.{UserCreated, UserSuspended, UserReinstated}

  def handle(%UserCreated{} = event, _metadata) do
    attrs =
      event
      |> Map.from_struct()
      |> User.changeset()
      |> Repo.insert!()

    :ok
  end

  def handle(%UserSuspended{id: id} = event, _metadata) do
    attrs = Map.from_struct(event)

    Users.get_user(id: id)
    |> User.changeset(attrs)
    |> Repo.update!()

    :ok
  end

  def handle(%UserReinstated{id: id} = event, _metadata) do
    attrs = Map.from_struct(event)

    Users.get_user(id: id)
    |> User.changeset(attrs)
    |> Repo.update!()

    :ok
  end
end
