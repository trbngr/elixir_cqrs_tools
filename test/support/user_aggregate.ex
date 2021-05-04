defmodule UserAggregate do
  defstruct []

  def execute(_state, _cmd), do: nil

  def apply(state, _), do: state
end
