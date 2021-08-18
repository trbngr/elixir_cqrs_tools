defmodule GetUserFriends do
  use Cqrs.Query

  filter :user_id, :binary_id, required: true

  @impl true
  def handle_create([user_id: user_id], _opts) do
    from u in User, where: u.id == ^user_id
  end

  @impl true
  def handle_execute(%Ecto.Query{wheres: [%{params: params}]}, _opts) do
    send(self(), {:friends_query_params, params})
    []
  end
end
