defmodule Cqrs.AbsintheTest do
  use ExUnit.Case

  alias Absinthe.Type.Enum

  test "enum is defined" do
    assert %Enum{values: values} = Absinthe.Schema.lookup_type(AbsintheSchema, :widget_status)
    assert [:new, :old] == Map.keys(values)
  end

  describe "middleware" do
    test "is executed for query" do
      Absinthe.run(
        """
        query user {
          getUser(email: "chris@example.com") {
            name
          }
        }
        """,
        AbsintheSchema
      )

      assert_receive(:before_resolve)
      assert_receive(:after_resolve)
    end

    test "is executed for connection query" do
      Absinthe.run(
        """
        query users {
          getUsers(first: 5) {
            edges{
              node{
                name
              }
            }
          }
        }
        """,
        AbsintheSchema
      )

      assert_receive(:before_resolve)
      assert_receive(:after_resolve)
    end

    test "is executed for mutation" do
      Absinthe.run(
        """
        mutation CreateUser {
          createUser(name: "chris", email: "chris@example.com")
        }
        """,
        AbsintheSchema
      )

      assert_receive(:before_resolve)
      assert_receive(:after_resolve)
    end
  end
end
