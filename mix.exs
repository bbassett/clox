defmodule Clox.Mixfile do
  use Mix.Project

  def project do
    [app: :clox,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{ :timex, "~> 0.13.4" },
     { :excheck, "~> 0.2.3", only: [:dev, :test] },
     { :triq, github: "krestenkrab/triq", only: [:dev, :test] }]
  end
end
