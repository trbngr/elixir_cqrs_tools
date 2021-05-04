
  defmodule GetUser do
    use Cqrs.Query
    alias User

    filter :email, :string, required: true

    @impl true
    def handle_validate(filters, _opts) do
      Ecto.Changeset.validate_format(filters, :email, ~r/@/)
    end

    @impl true
    def handle_create([email: email], _opts) do
      from u in User, where: u.email == ^email
    end

    @impl true
    def handle_execute(_query, _opts) do
      {:ok,
       %User{
         email: "chris@example.com",
         id: "052c1984-74c9-522f-858f-f04f1d4cc786",
         name: "chris"
       }}
    end
  end
