defmodule Example.UsersTest do
  use ExUnit.Case
  alias Example.Users

  defp load_user(result) do
    with {:ok, id} <- ExecutionResultHelper.aggregate_id(result) do
      Users.get_user(id: id)
    end
  end

  defp create(attrs), do: Users.create_user!(attrs, then: &load_user/1)
  defp suspend(attrs), do: Users.suspend_user(attrs, then: &load_user/1)
  defp reinstate(attrs), do: Users.reinstate_user(attrs, then: &load_user/1)

  defp delete_user(user) do
    Example.Repo.delete!(user)
  end

  test "create user" do
    user = create(name: "chris", email: "chris1@example.com")
    assert %{name: "chris", email: "chris1@example.com"} = user
    delete_user(user)
  end

  test "suspend user" do
    %{id: id} = user = create(%{name: "chris", email: "chris2@example.com"})
    assert %{status: :suspended} = suspend(id: id)
    delete_user(user)
  end

  test "reinstate user" do
    %{id: id} = user = create(name: "chris", email: "chris3@example.com")
    _ = suspend(id: id)
    assert %{status: :active} = reinstate(id: id)
    delete_user(user)
  end

  describe "list users" do
    setup do
      for n <- 10..14 do
        Users.create_user(name: "sarah", email: "sarah#{n}@example.com")
      end

      for n <- 15..19 do
        Users.create_user(name: "luke", email: "luke#{n}@example.com")
      end

      :ok
    end

    test "by name" do
      assert 5 = Users.list_users(name: "sarah") |> Enum.count()
    end

    test "by email" do
      assert 1 = Users.list_users(email: "luke16@example.com") |> Enum.count()
    end

    test "no filters" do
      assert 10 = Users.list_users() |> Enum.count()
    end
  end
end
