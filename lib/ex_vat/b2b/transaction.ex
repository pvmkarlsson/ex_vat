defmodule ExVat.B2B.Transaction do
  @moduledoc """
  Represents the result of a B2B transaction validation.

  This struct contains all information needed to determine VAT treatment
  for a cross-border B2B transaction within or outside the EU.

  ## Fields

    * `:seller_country` - Seller's country code (e.g., "SE")
    * `:buyer_country` - Buyer's country code (e.g., "DE")
    * `:seller_vat` - Seller's VAT number
    * `:buyer_vat` - Buyer's VAT number
    * `:seller_valid` - Whether seller's VAT number is valid
    * `:buyer_valid` - Whether buyer's VAT number is valid
    * `:same_country` - Whether both parties are in the same country
    * `:cross_border_eu` - Whether it's a cross-border EU transaction
    * `:reverse_charge` - Whether reverse charge mechanism applies
    * `:tax_treatment` - The applicable tax treatment type
    * `:vat_rate` - The applicable VAT rate (percentage)
    * `:seller_result` - Full validation result for seller (if online validation)
    * `:buyer_result` - Full validation result for buyer (if online validation)
    * `:invoice_note` - Suggested invoice note for this transaction type

  ## Tax Treatment Types

    * `:domestic` - Same country sale, standard VAT applies
    * `:reverse_charge` - Cross-border EU B2B, buyer self-assesses VAT
    * `:standard` - Cross-border EU B2C or invalid VAT, seller's country VAT
    * `:export` - Sale from EU to non-EU, zero-rated
    * `:import` - Purchase from non-EU into EU
    * `:outside_eu` - Both parties outside EU

  ## Example

      {:ok, %ExVat.B2B.Transaction{
        seller_country: "SE",
        buyer_country: "DE",
        seller_valid: true,
        buyer_valid: true,
        same_country: false,
        cross_border_eu: true,
        reverse_charge: true,
        tax_treatment: :reverse_charge,
        vat_rate: 0,
        invoice_note: "VAT reverse charge applies..."
      }} = ExVat.B2B.validate_transaction("SE", "556012345601", "DE", "123456789")
  """

  @type tax_treatment ::
          :domestic
          | :reverse_charge
          | :standard
          | :export
          | :import
          | :outside_eu

  @type t :: %__MODULE__{
          seller_country: String.t(),
          buyer_country: String.t(),
          seller_vat: String.t(),
          buyer_vat: String.t(),
          seller_valid: boolean(),
          buyer_valid: boolean(),
          same_country: boolean(),
          cross_border_eu: boolean(),
          reverse_charge: boolean(),
          tax_treatment: tax_treatment(),
          vat_rate: number() | nil,
          seller_result: ExVat.Result.t() | nil,
          buyer_result: ExVat.Result.t() | nil,
          invoice_note: String.t() | nil
        }

  defstruct [
    :seller_country,
    :buyer_country,
    :seller_vat,
    :buyer_vat,
    :seller_valid,
    :buyer_valid,
    :same_country,
    :cross_border_eu,
    :reverse_charge,
    :tax_treatment,
    :vat_rate,
    :seller_result,
    :buyer_result,
    :invoice_note
  ]
end
