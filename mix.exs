defmodule Clox.Mixfile do
  use Mix.Project

  def project do
    [app: :clox,
     version: "0.2.0",
     elixir: "~> 1.3",
     description: "time series date keys",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  defp deps do
    [{ :timex, "~> 2.2.1" },
     { :excheck, "~> 0.4.0", only: [:dev, :test] },
     { :triq, github: "krestenkrab/triq", only: [:dev, :test] },
     { :ex_doc, ">= 0.0.0", only: :dev }]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/clox"}]
  end
end
