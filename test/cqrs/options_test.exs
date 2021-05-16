defmodule Cqrs.OptionsTest do
  use ExUnit.Case, async: true

  defmodule TestCommand do
    use Cqrs.Command

    option :count, :integer, default: 5

    def handle_validate(command, opts) do
      send(self(), {:command_validate, Enum.into(opts, %{})})
      command
    end

    def handle_dispatch(_command, opts) do
      send(self(), {:command_dispatch, Enum.into(opts, %{})})
    end
  end

  defmodule TestQuery do
    use Cqrs.Query

    option :count, :integer, default: 5

    def handle_create(_filters, opts) do
      send(self(), {:query_create, Enum.into(opts, %{})})
      %Ecto.Query{}
    end

    def handle_execute(_query, opts) do
      send(self(), {:query_execute, Enum.into(opts, %{})})
      nil
    end
  end

  describe "count option" do
    test "defaults value" do
      TestCommand.new() |> TestCommand.dispatch()
      assert_receive({:command_validate, %{count: 5}})
      assert_receive({:command_dispatch, %{count: 5}})

      TestQuery.new() |> TestQuery.execute()
      assert_receive({:query_create, %{count: 5}})
      assert_receive({:query_execute, %{count: 5}})
    end

    test "can be set to custom values" do
      TestCommand.new(%{}, count: 20) |> TestCommand.dispatch(count: 30)
      assert_receive({:command_validate, %{count: 20}})
      assert_receive({:command_dispatch, %{count: 30}})

      TestQuery.new(%{}, count: 20) |> TestQuery.execute(count: 30)
      assert_receive({:query_create, %{count: 20}})
      assert_receive({:query_execute, %{count: 30}})
    end
  end

  describe "tag? option" do
    test "defaults to false" do
      TestCommand.new() |> TestCommand.dispatch()
      assert_receive({:command_validate, %{tag?: false}})
      assert_receive({:command_dispatch, %{tag?: false}})

      TestQuery.new() |> TestQuery.execute()
      assert_receive({:query_create, %{tag?: false}})
      assert_receive({:query_execute, %{tag?: false}})
    end

    test "can be set in new" do
      TestCommand.new(%{}, tag?: true) |> TestCommand.dispatch(tag?: false)
      assert_receive({:command_validate, %{tag?: true}})
      assert_receive({:command_dispatch, %{tag?: false}})

      TestQuery.new(%{}, tag?: true) |> TestQuery.execute(tag?: false)
      assert_receive({:query_create, %{tag?: true}})
      assert_receive({:query_execute, %{tag?: false}})
    end
  end
end
