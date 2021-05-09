defmodule CommandedApplication do
  def dispatch(command, _opts) do
    {:ok, UserDeactivated.new(command)}
  end
end
