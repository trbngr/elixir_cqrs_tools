defmodule ExampleApi.Plug.AbsintheContext do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    context = %{user: %{name: "api_user"}}
    Absinthe.Plug.put_options(conn, context: context)
  end
end
