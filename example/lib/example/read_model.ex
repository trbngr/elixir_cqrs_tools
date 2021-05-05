defmodule Example.ReadModel do
  use Supervisor

  alias Example.ReadModel.UserProjector

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      UserProjector
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defmodule Schema do
    defmacro __using__(_) do
      quote do
        use Ecto.Schema
        @primary_key {:id, :binary_id, autogenerate: false}
        @foreign_key_type :binary_id
      end
    end
  end
end
