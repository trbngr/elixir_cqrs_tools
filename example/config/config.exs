import Config

config :example, ecto_repos: [Example.Repo]

config :example, Example.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    event_store: Example.EventStore
  ]

config :commanded, Commanded.EventStore.Adapters.InMemory,
  serializer: Commanded.Serialization.JsonSerializer

config :example, Example.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id],
  migration_timestamps: [type: :utc_datetime]
