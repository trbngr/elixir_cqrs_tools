defmodule Cqrs.CommandTest do
  use ExUnit.Case, async: true

  doctest Cqrs.Command

  defmodule CommandOne do
    use Cqrs.Command

    field :name, :string

    option :do_other_thing, :integer, default: false
    option :do_thing, :boolean, default: false

    @impl true
    def handle_validate(changeset, opts) do
      send(self(), {:handle_validate, changeset, opts})
      changeset
    end

    @impl true
    def after_validate(command) do
      send(self(), {:after_validate, command})
      command
    end

    @impl true
    def before_dispatch(command, opts) do
      send(self(), {:before_dispatch, command, opts})

      if Keyword.get(opts, :return_error, false),
        do: {:error, :errored},
        else: command
    end

    @impl true
    def handle_dispatch(command, opts) do
      send(self(), {:handle_dispatch, command, opts})
      {:ok, :dispatched}
    end
  end

  describe "handle_validate callback" do
    test "is called on new()" do
      CommandOne.new([name: "chris"], value: :a)

      assert_receive({:handle_validate, %{data: %CommandOne{}}, opts})
      assert :a == Keyword.get(opts, :value)
    end

    test "is called on new!()" do
      CommandOne.new!([name: "chris"], value: :a)

      assert_receive({:handle_validate, %{data: %CommandOne{}}, opts})
      assert :a == Keyword.get(opts, :value)
    end
  end

  describe "after_validate callback" do
    test "is called on new() and triggers handle_validate again" do
      CommandOne.new([name: "chris"], value: :a)

      assert_receive({:after_validate, %CommandOne{name: "chris"}})

      assert_receive({:handle_validate, %{data: %CommandOne{}}, opts})
      assert :a == Keyword.get(opts, :value)
    end

    test "is called on new!() and triggers handle_validate again" do
      CommandOne.new!([name: "chris"], value: :a)

      assert_receive({:after_validate, %CommandOne{name: "chris"}})

      assert_receive({:handle_validate, %{data: %CommandOne{}}, opts})
      assert :a == Keyword.get(opts, :value)
    end
  end

  describe "before_dispatch callback" do
    test "is called on dispatch()" do
      CommandOne.new(name: "chris")
      |> CommandOne.dispatch(value: :a)

      assert_receive({:before_dispatch, %CommandOne{name: "chris"}, opts})
      assert :a == Keyword.get(opts, :value)
    end

    test "will not dispatch if {:error, _} is returned" do
      CommandOne.new(name: "chris")
      |> CommandOne.dispatch(value: :a, return_error: true)

      assert_receive({:before_dispatch, %CommandOne{name: "chris"}, opts})
      assert :a == Keyword.get(opts, :value)
      assert true == Keyword.get(opts, :return_error)

      refute_receive({:handle_dispatch, _command, _opts})
    end
  end

  describe "handle_dispatch callback" do
    test "is call on dispatch and the stars align before-hand" do
      assert {:ok, :dispatched} =
               CommandOne.new(name: "chris")
               |> CommandOne.dispatch(value: :a)

      assert_receive({:handle_dispatch, %CommandOne{name: "chris"}, opts})
      assert :a == Keyword.get(opts, :value)
    end
  end

  describe "options" do
    test "invalid options" do
      CommandOne.new(%{name: "chris"}, do_thing: 123, do_other_thing: false)
      |> IO.inspect(label: "~/code/personal/cqrs_tools/test/cqrs/command_test.exs:112")
    end
  end
end
