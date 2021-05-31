defmodule Example.Queries.GetThings do
  use Cqrs.Query

  filter :shit, :enum, values: [:s, :h, :i, :t]

  def handle_create(filters, _opts) do
    filters|> IO.inspect(label: "~/code/personal/cqrs_tools/example/lib/example/queries/get_things.ex:7")
    %Ecto.Query{}
  end

  def handle_execute(_query, _opts) do
    []
  end
end
