defmodule Cqrs.Clock.SystemClock do
  @moduledoc false
  @behaviour Cqrs.Clock
  def utc_now(_message), do: DateTime.utc_now()
end
