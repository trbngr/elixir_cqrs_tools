import Config

config :cqrs_tools, :absinthe_relay, repo: Example.Repo

config :example, ExampleApi.Endpoint,
  pubsub_server: Example.PubSub,
  http: [port: 4000],
  url: [host: "localhost"]

config :phoenix, :json_library, Jason

config :example, Example.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    event_store: Example.EventStore
  ]

config :commanded, Commanded.EventStore.Adapters.InMemory,
  serializer: Commanded.Serialization.JsonSerializer

if config_env() == :test do
  config :logger, :console, level: :warn
end
