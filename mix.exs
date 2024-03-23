defmodule Datacaster.MixProject do
  use Mix.Project

  def project do
    [
      app: :datacaster,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [
        gettext_default_namespace: "datacaster",
        gettext_default_backend: Datacaster.Gettext,
        gettext_module: Gettext,
        changeset_module: Ecto.Changeset
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, ">= 0.20.0", optional: true},
      {:ecto, "~> 3.0", optional: true}
    ]
  end
end
