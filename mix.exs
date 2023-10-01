defmodule AdeptDets.MixProject do
  use Mix.Project

  def project do
    [
      app: :adept_dets,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :app_tree, plt_add_apps: [:mix, :iex]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end
end
