defmodule ExVat.TEDB.Rate do
  @moduledoc """
  Represents a VAT rate from the EU TEDB (Taxes in Europe Database).

  This struct contains information about a specific VAT rate applicable
  in an EU member state, optionally for a specific category of goods/services.

  ## Fields

    * `:country` - ISO country code (e.g., "SE", "DE")
    * `:type` - Rate type (`:standard`, `:reduced`, `:super_reduced`, `:parking`, `:zero`, `:exempt`)
    * `:rate` - VAT rate as percentage (e.g., 25.0, 12.0, 0.0), nil for exempt
    * `:category` - TEDB category identifier if applicable (e.g., "FOODSTUFFS")
    * `:category_description` - Human-readable category description
    * `:cn_codes` - List of CN codes this rate applies to (goods)
    * `:cpa_codes` - List of CPA codes this rate applies to (services)
    * `:comment` - Additional notes about this rate
    * `:valid_from` - Date from which this rate is applicable

  ## Rate Types

    * `:standard` - Standard VAT rate (e.g., 25% in Sweden, 19% in Germany)
    * `:reduced` - Reduced rate for specific categories (e.g., 12% for food in Sweden)
    * `:super_reduced` - Super-reduced rate (some countries only)
    * `:parking` - Parking/transitional rate
    * `:zero` - Zero-rated (0%)
    * `:exempt` - VAT exempt (no rate applicable)

  ## Example

      %ExVat.TEDB.Rate{
        country: "SE",
        type: :reduced,
        rate: 12.0,
        category: "FOODSTUFFS",
        category_description: "Foodstuffs for human consumption",
        valid_from: ~D[2024-01-01]
      }
  """

  @type rate_type ::
          :standard
          | :reduced
          | :super_reduced
          | :parking
          | :zero
          | :exempt
          | :not_applicable
          | :out_of_scope
          | :unknown

  @type t :: %__MODULE__{
          country: String.t(),
          type: rate_type(),
          rate: number() | nil,
          category: String.t() | nil,
          category_description: String.t() | nil,
          cn_codes: [String.t()] | nil,
          cpa_codes: [String.t()] | nil,
          comment: String.t() | nil,
          valid_from: Date.t() | nil
        }

  defstruct [
    :country,
    :type,
    :rate,
    :category,
    :category_description,
    :cn_codes,
    :cpa_codes,
    :comment,
    :valid_from
  ]

  @doc """
  Returns true if this is a standard rate.
  """
  @spec standard?(t()) :: boolean()
  def standard?(%__MODULE__{type: :standard}), do: true
  def standard?(_), do: false

  @doc """
  Returns true if this is any kind of reduced rate.
  """
  @spec reduced?(t()) :: boolean()
  def reduced?(%__MODULE__{type: type}) when type in [:reduced, :super_reduced, :parking], do: true
  def reduced?(_), do: false

  @doc """
  Returns true if this rate is zero or exempt.
  """
  @spec zero_or_exempt?(t()) :: boolean()
  def zero_or_exempt?(%__MODULE__{type: type}) when type in [:zero, :exempt], do: true
  def zero_or_exempt?(%__MODULE__{rate: rate}) when rate == 0, do: true
  def zero_or_exempt?(_), do: false
end
