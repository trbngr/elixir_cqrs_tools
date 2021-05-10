defmodule Example.Users.Router do
  @moduledoc false
  use Commanded.Commands.Router

  alias Example.Users.UserAggregate
  alias Example.Users.Protocol.{CreateUser, ReinstateUser, SuspendUser}

  dispatch [CreateUser, ReinstateUser, SuspendUser],
    to: UserAggregate,
    identity: :id,
    identity_prefix: "user-",
    lifespan: __MODULE__

  @behaviour Commanded.Aggregates.AggregateLifespan
  def after_error(_), do: :timer.seconds(2)
  def after_event(_), do: :timer.seconds(2)
  def after_command(_), do: :timer.seconds(2)
end
