defmodule ExCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cluster,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: { ExCluster, [] }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :horde, "~> 0.3.0" },
      { :distillery, "~> 2.0" },
      { :libcluster, "~> 3.0" }
    ]
  end
end
