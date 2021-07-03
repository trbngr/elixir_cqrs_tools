defmodule Cqrs.Clock do
  @moduledoc false
  @callback utc_now(_message :: atom()) :: DateTime.t()

  def utc_now(message), do: clock().utc_now(message)

  defp clock do
    Application.get_env(:cqrs_tools, :clock, Cqrs.Clock.SystemClock)
  end
end
