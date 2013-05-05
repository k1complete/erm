defmodule Erm.Mixfile do
  use Mix.Project

  def project do
    [ app: :erm,
      version: "0.0.1",
      name: "erm",
      source_url: "https://github.com/k1complete/erm.git",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ {:ex_doc, github: "elixir-lang/ex_doc" }
    ]
  end
end
