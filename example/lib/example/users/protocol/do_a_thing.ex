defmodule Example.Users.Protocol.DoAThing do
  use Cqrs.Command

  field :status, :enum, values: [:a, :b, :c]

  def handle_dispatch(command, _opts) do
    command|> IO.inspect(label: "~/code/personal/cqrs_tools/example/lib/example/users/protocol/do_a_thing.ex:7")
    :ok
  end
end
