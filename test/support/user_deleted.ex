defmodule DeleteUser do
  use Cqrs.Command

  field :id, :integer

  def handle_dispatch(command, _opts) do
    {:ok, UserDeleted.new(command)}
  end

end

defmodule UserDeleted do
  use Cqrs.DomainEvent,
    from: DeleteUser,
    with: [:from],
    version: 2

end
