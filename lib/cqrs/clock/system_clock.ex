defmodule Cqrs.Clock.SystemClock do
  @behaviour Cqrs.Clock
  def utc_now(calendar), do: DateTime.utc_now(calendar)
end
