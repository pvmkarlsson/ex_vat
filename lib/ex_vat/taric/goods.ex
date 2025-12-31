defmodule ExVat.TARIC.Goods do
  @moduledoc """
  Represents goods information from the EU TARIC (Integrated Tariff) database.

  This struct contains the description and VAT rates for a CN (Combined Nomenclature)
  code, which is used to classify goods for customs and VAT purposes.

  ## Fields

    * `:cn_code` - The 10-digit CN code (e.g., "0101000000")
    * `:cn_code_formatted` - Human-readable format (e.g., "0101 00 00 00")
    * `:description` - Description of the goods in the requested language
    * `:language` - Language code of the description (e.g., "EN", "DE")
    * `:country` - Country for VAT rates (if rates were fetched)
    * `:rates` - List of applicable VAT rates (if rates were fetched)

  ## CN Code Structure

  CN codes follow a hierarchical structure:

    * 2 digits: Chapter (e.g., 01 = Live animals)
    * 4 digits: Heading (e.g., 0101 = Live horses)
    * 6 digits: Subheading (e.g., 010121 = Pure-bred breeding horses)
    * 8 digits: CN subheading
    * 10 digits: TARIC subheading (full code)

  ## Example

      %ExVat.TARIC.Goods{
        cn_code: "9706000000",
        cn_code_formatted: "9706 00 00 00",
        description: "Antiques of an age exceeding 100 years",
        language: "EN",
        country: "DE",
        rates: [
          %ExVat.TEDB.Rate{type: :reduced, rate: 7.0, category: "100_YEARS_OLD"},
          %ExVat.TEDB.Rate{type: :standard, rate: 19.0}
        ]
      }
  """

  alias ExVat.TEDB.Rate

  @type t :: %__MODULE__{
          cn_code: String.t(),
          cn_code_formatted: String.t() | nil,
          description: String.t(),
          language: String.t(),
          country: String.t() | nil,
          rates: [Rate.t()] | nil
        }

  defstruct [
    :cn_code,
    :cn_code_formatted,
    :description,
    :language,
    :country,
    :rates
  ]

  @doc """
  Formats a 10-digit CN code into human-readable format.

  ## Examples

      ExVat.TARIC.Goods.format_cn_code("9706000000")
      #=> "9706 00 00 00"

      ExVat.TARIC.Goods.format_cn_code("0101291000")
      #=> "0101 29 10 00"
  """
  @spec format_cn_code(String.t()) :: String.t()
  def format_cn_code(code) when is_binary(code) and byte_size(code) == 10 do
    <<a::binary-size(4), b::binary-size(2), c::binary-size(2), d::binary-size(2)>> = code
    "#{a} #{b} #{c} #{d}"
  end

  def format_cn_code(code) when is_binary(code) do
    # Pad and then format
    code
    |> String.pad_trailing(10, "0")
    |> format_cn_code()
  end

  @doc """
  Returns the chapter (first 2 digits) of a CN code.

  ## Examples

      ExVat.TARIC.Goods.chapter("9706000000")
      #=> "97"
  """
  @spec chapter(String.t() | t()) :: String.t()
  def chapter(%__MODULE__{cn_code: code}), do: chapter(code)
  def chapter(code) when is_binary(code), do: String.slice(code, 0, 2)

  @doc """
  Returns the heading (first 4 digits) of a CN code.

  ## Examples

      ExVat.TARIC.Goods.heading("9706000000")
      #=> "9706"
  """
  @spec heading(String.t() | t()) :: String.t()
  def heading(%__MODULE__{cn_code: code}), do: heading(code)
  def heading(code) when is_binary(code), do: String.slice(code, 0, 4)

  @doc """
  Returns true if this goods item has a reduced VAT rate available.
  """
  @spec has_reduced_rate?(t()) :: boolean()
  def has_reduced_rate?(%__MODULE__{rates: nil}), do: false
  def has_reduced_rate?(%__MODULE__{rates: rates}) do
    Enum.any?(rates, &Rate.reduced?/1)
  end

  @doc """
  Returns the lowest applicable VAT rate for this goods item.
  """
  @spec lowest_rate(t()) :: number() | nil
  def lowest_rate(%__MODULE__{rates: nil}), do: nil
  def lowest_rate(%__MODULE__{rates: []}) , do: nil
  def lowest_rate(%__MODULE__{rates: rates}) do
    rates
    |> Enum.map(& &1.rate)
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end
end
