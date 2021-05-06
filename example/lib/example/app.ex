defmodule Example.App do
  @moduledoc false
  use Commanded.Application,
    otp_app: :example,
    default_dispatch_opts: [
      consistency: :strong,
      returning: :execution_result
    ]

  router Example.Users.Router
end
