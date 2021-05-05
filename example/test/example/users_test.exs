defmodule Example.UsersTest do
  use ExUnit.Case
  alias Example.Users

  test "create user" do
    assert %{name: "chris", email: "chris1@example.com"} =
             Users.create_user(name: "chris", email: "chris1@example.com")
  end

  test "suspend user" do
    %{id: id} = Users.create_user(name: "chris", email: "chris2@example.com")
    assert %{status: :suspended} = Users.suspend_user(id: id)
  end

  test "reinstate user" do
    %{id: id} = Users.create_user(name: "chris", email: "chris3@example.com")
    _ = Users.suspend_user(id: id)
    assert %{status: :active} = Users.reinstate_user(id: id)
  end

  describe "list users" do
    setup do
      for n <- 10..14 do
        Users.create_user(name: "chris", email: "chris#{n}@example.com")
      end

      for n <- 15..19 do
        Users.create_user(name: "frank", email: "frank#{n}@example.com")
      end

      :ok
    end

    test "by name" do
      assert 5 = Users.list_users(name: "chris") |> Enum.count()
    end

    test "by email" do
      assert 1 = Users.list_users(email: "chris11@example.com") |> Enum.count()
    end

    test "no filters" do
      assert 10 = Users.list_users() |> Enum.count()
    end
  end
end
