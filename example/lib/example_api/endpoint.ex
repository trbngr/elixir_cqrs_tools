defmodule ExampleApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :example

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Corsica,
    origins: [~r{http\://localhost}],
    log: [rejected: :warn, invalid: :warn, accepted: false],
    allow_headers: :all,
    allow_credentials: true

  plug Plug.Session,
    store: :cookie,
    key: "_oval_key",
    signing_salt: "6gK2LZ+u"

  plug ExampleApi.Router
end
