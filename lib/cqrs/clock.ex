defmodule Cqrs.Clock do
  @callback utc_now(calendar :: Calendar.t()) :: DateTime.t()

  def utc_now(calendar \\ Calendar.ISO), do: clock().utc_now(calendar)

  defp clock do
    Application.get_env(:cqrs_tools, :clock, Cqrs.Clock.SystemClock)
  end
end
