defmodule ExVat.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/pvmkarlsson/ex_vat"

  def project do
    [
      app: :ex_vat,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "ExVat",
      source_url: @source_url,
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: ["test.integration": :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # HTTP client
      {:req, "~> 0.5"},

      # Development/Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp description do
    """
    A flexible EU VAT validation library with pluggable adapters.
    Supports the official EU VIES API and offline regex validation.
    Features include B2B cross-border VAT calculations, input normalization,
    automatic retry, and company information lookup.
    """
  end

  defp package do
    [
      name: "ex_vat",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "VIES API" => "https://ec.europa.eu/taxation_customs/vies/"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        "Core": [
          ExVat,
          ExVat.Result,
          ExVat.Error,
          ExVat.Format
        ],
        "Adapters": [
          ExVat.Adapter,
          ExVat.Adapter.Vies,
          ExVat.Adapter.Regex
        ],
        "B2B Utilities": [
          ExVat.B2B,
          ExVat.B2B.Transaction
        ],
        "VAT Rates (TEDB)": [
          ExVat.TEDB,
          ExVat.TEDB.Rate,
          ExVat.TEDB.Categories
        ],
        "Goods Classification (TARIC)": [
          ExVat.TARIC,
          ExVat.TARIC.Goods
        ]
      ]
    ]
  end

  defp aliases do
    [
      "test.integration": ["test --only integration"]
    ]
  end
end
