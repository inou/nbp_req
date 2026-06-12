defmodule NbpReq.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/inou/nbp_req"

  def project do
    [
      app: :nbp_req,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "HTTP client for the NBP Web API (Polish National Bank exchange rates and gold prices), built on Req.",
      package: package(),
      name: "NbpReq",
      source_url: @source_url,
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
      {:req, "~> 0.5"},
      {:plug, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url, "NBP Web API" => "https://api.nbp.pl/"}
    ]
  end

  defp docs do
    [
      main: "NbpReq",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end
end
