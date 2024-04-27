defmodule Datacaster.MixProject do
  use Mix.Project

  @source_url "https://github.com/emfy0/datacaster_elixir"

  def project do
    [
      app: :datacaster,
      version: "0.1.10",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,

      # Mix
      description: "Run-time type checker and transformer for Elixir",
      package: package(),
      source_url: @source_url,

      # Docs
      name: "Datacaster",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Datacaster.Application, []},
      env: [
        gettext_default_namespace: "datacaster",
        gettext_default_backend: Datacaster.Gettext,
        gettext_module: Gettext,
        changeset_module: Ecto.Changeset
      ]
    ]
  end

  defp package do
    [
      name: "datacaster",
      licenses: ["MIT"],
      maintainers: ["Pavel Egorov"],
      links: %{ "GitHub" => @source_url },
      files: ~w(.formatter.exs mix.exs README.md lib test)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, ">= 0.20.0", optional: true},
      {:ecto, "~> 3.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
