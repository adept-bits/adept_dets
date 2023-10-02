defmodule AdeptDets.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :adept_dets,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :app_tree, plt_add_apps: [:mix, :iex]],
      docs: docs()
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: Adept.Dets,
      source_ref: "v#{@version}",
      source_url: "https://github.com/adept-bits/adept_dets"
      # homepage_url: "http://kry10.com",
    ]
  end
end
