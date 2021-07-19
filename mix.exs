defmodule CqrsTools.MixProject do
  use Mix.Project

  @version "0.4.7"

  def project do
    [
      app: :cqrs_tools,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: "A collection of handy Elixir macros for CQRS applications.",
      source_url: "https://github.com/trbngr/elixir_cqrs_tools",
      docs: [
        main: "Cqrs",
        source_ref: "v#{@version}"
      ],
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/trbngr/elixir_cqrs_tools"}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.2"},
      {:jason, "~> 1.1", optional: true},
      {:absinthe, "~> 1.4", optional: true},
      {:absinthe_relay, "~> 1.4", optional: true},
      {:commanded, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:elixir_uuid, "~> 1.6", override: true, hex: :uuid_utils, only: :test},
      {:git_hooks, "~> 0.6.2", only: [:dev], runtime: false}
    ]
  end
end
