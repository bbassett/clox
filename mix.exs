defmodule Clox.Mixfile do
  use Mix.Project

  def project do
    [app: :clox,
     version: "0.1.1",
     elixir: "~> 1.0",
     description: "time series date keys",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
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

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/clox"}]
  end
end
