defmodule Example.ReadModel do
  @moduledoc false
  use Supervisor

  alias Example.ReadModel.UserProjector

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [UserProjector]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
