defmodule Cqrs.ValueObjectTest do
  use ExUnit.Case

  defmodule Persona do
    use Cqrs.ValueObject

    field :name, :string
    field :dob, :date
  end

  defmodule AssignThing do
    use Cqrs.Command

    field :thing, :string
    field :persona, Persona

    @impl true
    def handle_dispatch(command, _opts) do
      {:ok, command}
    end
  end

  test "yeah?" do
    assert {:ok, command} = AssignThing.new(thing: "sword", persona: %{name: "Bjorf", dob: "2030-05-02"})

    assert %AssignThing{thing: "sword", persona: persona} = command
    assert %Persona{name: "Bjorf", dob: ~D[2030-05-02]} = persona
  end
end
