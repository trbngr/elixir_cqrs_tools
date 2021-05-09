defmodule Example.Users.UserAggregate do
  defstruct [:id, :status]

  alias Example.Users.Protocol.{CreateUser, UserCreated}
  alias Example.Users.Protocol.{SuspendUser, UserSuspended}
  alias Example.Users.Protocol.{ReinstateUser, UserReinstated}

  def execute(%{id: nil}, %CreateUser{} = cmd), do: UserCreated.new(cmd)
  def execute(_state, %CreateUser{}), do: {:error, :user_already_created}

  def execute(%{id: nil}, _), do: {:error, :user_not_found}

  def execute(%{status: :active}, %SuspendUser{} = cmd), do: UserSuspended.new(cmd)
  def execute(_, %SuspendUser{}), do: nil

  def execute(%{status: :suspended}, %ReinstateUser{} = cmd), do: UserReinstated.new(cmd)
  def execute(_, %ReinstateUser{}), do: nil

  def apply(state, %UserCreated{id: id}), do: %{state | id: id, status: :active}
  def apply(state, %UserSuspended{}), do: %{state | status: :suspended}
  def apply(state, %UserReinstated{}), do: %{state | status: :active}
end
