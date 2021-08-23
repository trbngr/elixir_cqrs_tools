defmodule Cqrs.AbsintheTest do
  use ExUnit.Case

  alias Absinthe.Type.Enum

  test "enum is defined" do
    assert %Enum{values: values} = Absinthe.Schema.lookup_type(AbsintheSchema, :widget_status)
    assert [:new, :old] == Map.keys(values)
  end

  describe "filters from parent" do
    test "works for connections" do
      Absinthe.run(
        """
          query userAndFriends {
            getUser(email: "chris@example.com") {
              name
              friendsConnection(first: 5){
                edges {
                  node{
                    name
                  }
                }
              }
            }
          }
        """,
        AbsintheSchema
      )

      assert_receive {:friends_query_params, [{"052c1984-74c9-522f-858f-f04f1d4cc786", {0, :id}}]}
    end

    test "works for queries" do
      Absinthe.run(
        """
          query userAndFriends {
            getUser(email: "chris@example.com") {
              name
              friends{
                name
              }
            }
          }
        """,
        AbsintheSchema
      )

      assert_receive {:friends_query_params, [{"052c1984-74c9-522f-858f-f04f1d4cc786", {0, :id}}]}
    end
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

  describe "assign_parent_to_field" do
    setup do
      Absinthe.run(
        """
        mutation CreateUser {
          createUser(name: "chris", email: "chris@example.com")
        }
        """,
        AbsintheSchema
      )
    end

    test "returns parent user" do
      {:ok, data} =
        Absinthe.run(
          """
          query user {
            getUser(email: "chris@example.com") {
              name
              assignParent {
                parentName: name
              }
            }
          }
          """,
          AbsintheSchema
        )

      assert %{"name" => name, "assignParent" => %{"parentName" => parent_name}} = get_in(data, [:data, "getUser"])

      assert name == parent_name
    end
  end
end
