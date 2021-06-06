defmodule MapReduce.MixProject do
  use Mix.Project

  def project do
    [
      app: :map_reduce,
      version: "0.1.0",
      elixir: "~> 1.12.0",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      escript: [main_module: MapReduce],
      xref: [exclude: [:crypto]],
      name: "map_reduce",
      source_url: "https://github.com/Elixir-MapReduce/map_reduce"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:poison,"~> 3.1"}
    ]
  end

  defp description() do
    "This package allows you to use the MapReduce paradigm to solve a question,
    given that you have the functions map and reduce for that problem"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "map_reduce",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Elixir-MapReduce/map_reduce"}
    ]
  end
end
