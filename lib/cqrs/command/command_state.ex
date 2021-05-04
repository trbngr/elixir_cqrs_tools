defmodule Cqrs.Command.CommandState do
  @moduledoc false
  alias Ecto.Changeset

  @type t :: %__MODULE__{
          changeset: Changeset.t(),
          errors: list(),
          valid?: boolean()
        }

  defstruct [:changeset, :errors, :valid?]

  def new(%Changeset{valid?: valid?} = changeset) do
    errors = Changeset.traverse_errors(changeset, fn {err, _opts} -> err end)
    %__MODULE__{changeset: changeset, errors: errors, valid?: valid?}
  end

  def apply(%__MODULE__{changeset: changeset}) do
    Changeset.apply_action(changeset, :create)
  end

  def apply_changes(%__MODULE__{changeset: changeset}) do
    Changeset.apply_changes(changeset)
  end

  def merge(%Changeset{} = new_changes, %__MODULE__{changeset: changeset}) do
    changeset
    |> Changeset.merge(new_changes)
    |> new()
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{changeset: changeset, errors: errors}, opts) do
      %{valid?: valid?, changes: changes, data: %{__struct__: type}} = changeset

      changes = Map.delete(changes, :created_at)

      [command_type | _] =
        type
        |> Module.split()
        |> Enum.reverse()

      if valid?,
        do: concat(["##{command_type}<", to_doc(changes, opts), ">"]),
        else: concat(["##{command_type}<errors: ", to_doc(errors, opts), ">"])
    end
  end
end
