defmodule ExecutionResultHelper do
  @type execution_result ::
          {:ok, result :: Commanded.Commands.ExecutionResult.t()}
          | {:error, reason :: term}
          | {:error, {:invalid_command, Command.t()}}

  @type return_value ::
          {:ok, term()}
          | {:error, reason :: term}
          | {:error, {:invalid_command, Command.t()}}

  @spec aggregate_id(execution_result()) :: return_value
  def aggregate_id({:ok, %{aggregate_state: %{id: id}}}), do: {:ok, id}
  def aggregate_id(other), do: other

  @type mapper :: fun() | nil
  @spec first_event(execution_result()) :: return_value
  @spec first_event(execution_result(), mapper()) :: return_value
  def first_event(execution_result, mapper \\ nil)
  def first_event({:ok, %{events: [first | _rest]}}, nil), do: {:ok, first}

  def first_event({:ok, %{events: [first | _rest]}}, mapper) when is_function(mapper, 1),
    do: {:ok, mapper.(first)}

  def first_event({:ok, _}, mapper) when is_function(mapper),
    do: raise("Expected mapper to be a function with an arity of 1")

  def first_event(other, _mapper), do: other

  @spec events(execution_result()) :: list() | return_value()
  @spec events(execution_result(), mapper()) :: list() | return_value()
  def events({:ok, %{events: events}}, nil), do: {:ok, events}

  def events({:ok, %{events: events}}, mapper) when is_function(mapper, 1),
    do: {:ok, mapper.(events)}

  def events({:ok, _}, mapper) when is_function(mapper),
    do: raise("Expected mapper to be a function with an arity of 1")

  def events(other), do: other
end
