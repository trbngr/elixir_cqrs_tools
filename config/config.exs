import Config

if config_env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format --check-formatted"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix test --color"},
          {:cmd, "echo 'success!'"}
        ]
      ]
    ]
end
