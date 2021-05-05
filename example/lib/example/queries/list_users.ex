defmodule Example.Queries.ListUsers do
  use Cqrs.Query
  alias Example.{Repo, ReadModel.User}

  @moduledoc """
  Generates a list of [users](`#{User}`).
  """

  filter :email, :string
  filter :name, :string

  @impl true
  def handle_create(filters, opts) do
    order_by = Keyword.get(opts, :order_by, :name)
    limit = Keyword.get(opts, :limit, 25)

    query = from u in User, order_by: ^order_by, limit: ^limit

    Enum.reduce(filters, query, fn
      {:email, email}, query -> from q in query, where: q.email == ^email
      {:name, name}, query -> from q in query, where: q.name == ^name
      _, query -> query
    end)
  end

  @impl true
  def handle_execute(query, opts), do: Repo.all(query, opts)
end
