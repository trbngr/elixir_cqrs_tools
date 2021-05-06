defmodule Cqrs.CommandValidation do
  @moduledoc """
  Defines validation functions for a validated command.

  ## Example

      defmodule CreateUser do
        use Cqrs.Command
        alias Cqrs.CommandValidation

        field :email, :string
        field :name, :string
        field :id, :binary_id, internal: true

        derive_event UserCreated

        @impl true
        def handle_validate(command, _opts) do
          Ecto.Changeset.validate_format(command, :email, ~r/@/)
        end

        @impl true
        def after_validate(%{email: email} = command) do
          Map.put(command, :id, UUID.uuid5(:oid, email))
        end

        @impl true
        def before_dispatch(command, _opts) do
          command
          |> CommandValidation.new()
          |> CommandValidation.add(&ensure_uniqueness/1)
          |> CommandValidation.run()
        end

        @impl true
        def handle_dispatch(_command, _opts) do
          {:ok, :dispatched}
        end

        defp ensure_uniqueness(%{id: id}) do
          if Repo.exists?(from u in User, where: u.id == ^id),
            do: {:error, "user already exists"},
            else: :ok
        end
      end

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
