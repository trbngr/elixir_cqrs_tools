defmodule GetUsers do
  use Cqrs.Query

  @impl true
  def handle_create(_filters, _opts) do
    User
  end

  @impl true
  def handle_execute(_query, _opts) do
    [
      %User{
        email: "chris@example.com",
        id: "052c1984-74c9-522f-858f-f04f1d4cc786",
        name: "chris"
      }
    ]
  end
end
