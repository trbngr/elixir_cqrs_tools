defmodule Example.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :example,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "example",
        source_ref: "v#{@version}"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Example.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cqrs_tools, path: ".."},
      {:commanded, "~> 1.2"},
      {:ecto, "~> 3.6"},
      {:jason, "~> 1.2"},
      {:etso, "~> 0.1.5"},
      {:phoenix, "~> 1.5"},
      {:corsica, "~> 1.1"},
      {:plug_cowboy, "~> 2.4"},
      {:absinthe, "~> 1.6"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_relay, "~> 1.5"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
