defmodule Example.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :example, adapter: Etso.Adapter
end
