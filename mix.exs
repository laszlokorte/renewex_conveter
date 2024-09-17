defmodule RenewexConverter.MixProject do
  use Mix.Project

  @source_url "https://github.com/laszlokorte/renewex_converter"
  @version "0.12.0"

  def project do
    [
      app: :renewex_converter,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      docs: [
        # The main page in the docs
        extras: ["README.md"],
        source_url: @source_url,
        logo: "guides/images/logo-square.png"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34.0", only: :dev, runtime: false},
      {:renewex, "~> 0.12.0"}
    ]
  end

  defp description() do
    "Converter to convert parsed renew files into layers and back."
  end

  defp package() do
    [
      name: "renewex_converter",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/laszlokorte/renewex_converter",
        "Renew" => "http://www.renew.de"
      }
    ]
  end
end
