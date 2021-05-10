defmodule Cqrs.CommandValidationTest do
  use ExUnit.Case
  alias Cqrs.CommandValidation

  defp validate_ok(_), do: :ok
  defp validate_nil(_), do: nil
  defp validate_map(_), do: %{}
  defp validate_timeout(_), do: Process.sleep(1000)
  defp validate_error(_), do: {:error, :shit_happens}
  defp validate_error2(_), do: {:error, :a_lot_of}

  test "returns one error" do
    assert {:error, [:shit_happens]} =
             %{}
             |> CommandValidation.new()
             |> CommandValidation.add(&validate_ok/1)
             |> CommandValidation.add(&validate_error/1)
             |> CommandValidation.add(&validate_nil/1)
             |> CommandValidation.add(&validate_map/1)
             |> CommandValidation.run()
  end

  test "returns two errors" do
    assert {:error, [:a_lot_of, :shit_happens]} =
             %{}
             |> CommandValidation.new()
             |> CommandValidation.add(&validate_ok/1)
             |> CommandValidation.add(&validate_error/1)
             |> CommandValidation.add(&validate_nil/1)
             |> CommandValidation.add(&validate_error2/1)
             |> CommandValidation.run()
  end

  test "timeouts are handled" do
    assert {:error, [:shit_happens, :timeout]} =
             %{}
             |> CommandValidation.new()
             |> CommandValidation.add(&validate_error/1)
             |> CommandValidation.add(&validate_ok/1)
             |> CommandValidation.add(&validate_nil/1)
             |> CommandValidation.add(&validate_timeout/1)
             |> CommandValidation.run(timeout: 50)
  end
end
