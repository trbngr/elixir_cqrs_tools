defmodule Cqrs.AbsintheTest do
  use ExUnit.Case

  alias Absinthe.Type.Enum

  test "enum is defined" do
    assert %Enum{values: values} = Absinthe.Schema.lookup_type(AbsintheSchema, :widget_status)
    assert [:new, :old] == Map.keys(values)
  end
end
