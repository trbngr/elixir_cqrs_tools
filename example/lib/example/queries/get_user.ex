defmodule Example.Queries.GetUser do
  use Cqrs.Query
  alias Example.{Repo, ReadModel.User}

  @moduledoc """
  Gets a single [user](`#{User}`).

  At least one filter is required.
  """

  @desc "The ID of the user"
  filter :id, :binary_id
  filter :email, :string

  @desc "The name of the user."
  filter :get_user_name, :string, deprecate: "this is a stupid filter. Don't expect to use it soon."

  binding :user, User

  option :exists?, :boolean,
    default: false,
    description: "If `true`, only check if the user exists."

  @impl true
  def handle_create([], _opts), do: {:error, :missing_filters}

  @impl true
  def handle_create(filters, _opts) do
    query = from(u in User, as: :user)

    Enum.reduce(filters, query, fn
      {:id, id}, query -> from q in query, where: q.id == ^id
      {:email, email}, query -> from q in query, where: q.email == ^email
      {:name, name}, query -> from q in query, where: q.name == ^name
      _, query -> query
    end)
  end

  @impl true
  def handle_execute(query, opts) do
    case Keyword.get(opts, :exists?) do
      true -> Repo.exists?(query, opts)
      false -> Repo.one(query, opts)
    end
  end
end
