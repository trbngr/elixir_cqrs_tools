defmodule Cqrs.AbsintheTest do
  use ExUnit.Case

  alias Absinthe.Type.{Enum, Field, Object, InputObject}

  test "enum is defined" do
    assert %Enum{values: values} = Absinthe.Schema.lookup_type(AbsintheSchema, :widget_status)
    assert [:new, :old] == Map.keys(values)
  end

  test "value object is defined" do
    assert %InputObject{fields: fields} = Absinthe.Schema.lookup_type(AbsintheSchema, :persona_input)

    field_names = Map.keys(fields)

    assert Elixir.Enum.member?(field_names, :dob)
    assert Elixir.Enum.member?(field_names, :name)
  end

  test "mutation can use value objects as args" do
    assert %Object{fields: fields} = Absinthe.Schema.lookup_type(AbsintheSchema, "RootMutationType")

    assert %Field{args: args} = Map.get(fields, :change_widget_status)

    arg_names = Map.keys(args)

    assert Elixir.Enum.member?(arg_names, :status)
    assert Elixir.Enum.member?(arg_names, :persona)
  end
end
