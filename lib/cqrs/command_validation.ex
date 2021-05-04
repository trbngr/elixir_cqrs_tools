defmodule Cqrs.CommandValidation do
  @moduledoc """
  Defines validation functions for a validated command.
  """

  @type command :: map()
  @type t :: %__MODULE__{command: command(), validations: list()}
  @type validation_function ::
          (command() -> any() | {:error, any()})
          | (command(), keyword() -> any() | {:error, any()})

  defstruct [:command, validations: []]

  @doc """
  Creates a new `Cqrs.CommandValidation` struct.
  """
  @spec new(command()) :: t()
  def new(command), do: %__MODULE__{command: command}


  @doc """
  Adds a `validation_function` to the list of validations to run.
  """
  @spec add(t(), validation_function()) :: t()
  def add(%__MODULE__{validations: validations} = validation, fun)
      when is_function(fun, 1) or is_function(fun, 2) do
    %{validation | validations: [fun | validations]}
  end

  @doc """
  Runs the list of 'validation_function' functions
  """
  @spec run(t(), keyword()) :: {:ok, command()} | {:error, list()}
  def run(%__MODULE__{command: command} = validation, opts \\ []) do
    case collect_errors(validation, opts) do
      [] -> {:ok, command}
      errors -> {:error, Keyword.get_values(errors, :error)}
    end
  end

  defp collect_errors(%{command: command, validations: validations}, opts) do
    run_validation = fn
      fun, acc when is_function(fun, 1) -> [fun.(command) | acc]
      fun, acc when is_function(fun, 2) -> [fun.(command, opts) | acc]
    end

    validations
    |> Enum.reduce([], run_validation)
    |> Enum.filter(&match?({:error, _}, &1))
  end
end
