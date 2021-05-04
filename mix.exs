defmodule CqrsTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :cqrs_tools,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: [
        main: "Cqrs"
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
      {:jason, "~> 1.2", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:commanded, "~> 1.2", only: :dev, runtime: false},
      {:elixir_uuid, "~> 1.6", override: true, hex: :uuid_utils, only: :test}
    ]
  end
end
