defmodule CqrsTools.MixProject do
  use Mix.Project

  @version "0.1.1"

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
      ],
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
      {:commanded, "~> 1.2", only: [:dev, :test], runtime: false},
      {:elixir_uuid, "~> 1.6", override: true, hex: :uuid_utils, only: :test}
    ]
  end
end
