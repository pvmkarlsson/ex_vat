defmodule ExVat.B2B do
  @moduledoc """
  B2B (Business-to-Business) cross-border VAT utilities.

  This module provides comprehensive functions to determine VAT treatment for
  cross-border transactions within and outside the EU.

  ## EU VAT Reverse Charge

  The reverse charge mechanism shifts VAT liability from seller to buyer
  when ALL of the following conditions are met:

  1. Seller is established in an EU member state
  2. Buyer is established in a different EU member state
  3. Buyer has a valid VAT number
  4. Transaction is B2B (not B2C)

  When reverse charge applies:
  - Seller issues invoice without VAT (0%)
  - Buyer self-assesses and pays VAT in their country
  - Invoice must reference "Reverse charge"

  ## Tax Treatment Types

  | Treatment | Description |
  |-----------|-------------|
  | `:domestic` | Same country sale, standard VAT applies |
  | `:reverse_charge` | Cross-border EU B2B, buyer self-assesses |
  | `:standard` | Cross-border EU B2C, seller's country VAT |
  | `:export` | Sale to non-EU, zero-rated |
  | `:import` | Purchase from non-EU into EU |
  | `:outside_eu` | Both parties outside EU |

  ## Standard VAT Rates (2024)

  The module includes standard VAT rates for all EU member states.
  Use `standard_rate/1` to retrieve them.

  ## Usage

      # Validate a transaction
      {:ok, tx} = ExVat.B2B.validate_transaction("SE", "556012345601", "DE", "123456789")
      tx.reverse_charge   #=> true
      tx.tax_treatment    #=> :reverse_charge

      # Check if reverse charge applies (with validation)
      ExVat.B2B.reverse_charge?("SE", "556012345601", "DE", "123456789")
      #=> true

      # Check if reverse charge applies (without validation)
      ExVat.B2B.reverse_charge_applies?("SE", "DE", true)
      #=> true

      # Get tax treatment
      ExVat.B2B.tax_treatment("SE", "DE", buyer_vat_valid: true)
      #=> :reverse_charge

      # Get VAT rate
      ExVat.B2B.standard_rate("SE")
      #=> 25
  """

  alias ExVat
  alias ExVat.B2B.Transaction

  # EU member states (including EL for Greece, XI for Northern Ireland)
  @eu_country_codes ~w(AT BE BG CY CZ DE DK EE EL ES FI FR GR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK XI)
  @eu_country_set MapSet.new(@eu_country_codes)

  # Standard VAT rates by country (as of 2024)
  # Returns Decimal if available, otherwise integer
  @standard_vat_rates %{
    "AT" => 20,
    "BE" => 21,
    "BG" => 20,
    "CY" => 19,
    "CZ" => 21,
    "DE" => 19,
    "DK" => 25,
    "EE" => 22,
    "EL" => 24,
    "ES" => 21,
    "FI" => 24,
    "FR" => 20,
    "GR" => 24,
    "HR" => 25,
    "HU" => 27,
    "IE" => 23,
    "IT" => 22,
    "LT" => 21,
    "LU" => 17,
    "LV" => 21,
    "MT" => 18,
    "NL" => 21,
    "PL" => 23,
    "PT" => 23,
    "RO" => 19,
    "SE" => 25,
    "SI" => 22,
    "SK" => 20,
    "XI" => 20
  }

  @type tax_treatment ::
          :domestic
          | :reverse_charge
          | :standard
          | :export
          | :import
          | :outside_eu

  # ============================================================================
  # VAT Rates
  # ============================================================================

  @doc """
  Returns the standard VAT rate for an EU country.

  ## Examples

      iex> ExVat.B2B.standard_rate("SE")
      25

      iex> ExVat.B2B.standard_rate("DE")
      19

      iex> ExVat.B2B.standard_rate("US")
      nil
  """
  @spec standard_rate(String.t()) :: number() | nil
  def standard_rate(country) when is_binary(country) do
    country = normalize_country(country)
    Map.get(@standard_vat_rates, country)
  end

  def standard_rate(_), do: nil

  @doc """
  Returns the standard VAT rate as a Decimal (requires Decimal library).

  Falls back to regular number if Decimal is not available.

  ## Examples

      iex> ExVat.B2B.standard_rate_decimal("SE")
      #Decimal<25>
  """
  @spec standard_rate_decimal(String.t()) :: Decimal.t() | number() | nil
  def standard_rate_decimal(country) do
    case standard_rate(country) do
      nil -> nil
      rate -> maybe_decimal(rate)
    end
  end

  @doc """
  Returns all standard VAT rates as a map.

  ## Examples

      iex> ExVat.B2B.standard_rates()
      %{"AT" => 20, "BE" => 21, ...}
  """
  @spec standard_rates() :: %{String.t() => number()}
  def standard_rates, do: @standard_vat_rates

  # ============================================================================
  # EU Membership
  # ============================================================================

  @doc """
  Returns true if the country is an EU member state.

  Supports both EL and GR for Greece.

  ## Examples

      iex> ExVat.B2B.eu_member?("SE")
      true

      iex> ExVat.B2B.eu_member?("US")
      false

      iex> ExVat.B2B.eu_member?("GR")
      true
  """
  @spec eu_member?(String.t()) :: boolean()
  def eu_member?(country) when is_binary(country) do
    MapSet.member?(@eu_country_set, normalize_country(country))
  end

  def eu_member?(_), do: false

  @doc """
  Returns the list of EU member state country codes.
  """
  @spec eu_member_states() :: [String.t()]
  def eu_member_states, do: @eu_country_codes

  # ============================================================================
  # Tax Treatment
  # ============================================================================

  @doc """
  Determines the tax treatment for a transaction.

  ## Parameters

    * `seller_country` - Seller's country code
    * `buyer_country` - Buyer's country code
    * `opts` - Options:
      * `:buyer_vat_valid` - Whether buyer has valid VAT number (default: `true`)
      * `:b2b` - Whether this is a B2B transaction (default: `true`)

  ## Returns

    * `:domestic` - Same country sale, standard VAT applies
    * `:reverse_charge` - Cross-border EU B2B with valid VAT, buyer self-assesses
    * `:standard` - Cross-border EU B2C or invalid VAT, seller's country VAT
    * `:export` - Sale from EU to non-EU, zero-rated
    * `:import` - Purchase from non-EU into EU
    * `:outside_eu` - Both parties outside EU

  ## Examples

      # Cross-border EU B2B with valid VAT
      iex> ExVat.B2B.tax_treatment("SE", "DE", buyer_vat_valid: true)
      :reverse_charge

      # Same country
      iex> ExVat.B2B.tax_treatment("SE", "SE")
      :domestic

      # Cross-border EU B2C
      iex> ExVat.B2B.tax_treatment("SE", "DE", b2b: false)
      :standard

      # Export outside EU
      iex> ExVat.B2B.tax_treatment("SE", "US")
      :export

      # Import from outside EU
      iex> ExVat.B2B.tax_treatment("US", "DE")
      :import
  """
  @spec tax_treatment(String.t(), String.t(), keyword()) :: tax_treatment()
  def tax_treatment(seller_country, buyer_country, opts \\ []) do
    buyer_vat_valid = Keyword.get(opts, :buyer_vat_valid, true)
    b2b = Keyword.get(opts, :b2b, true)

    seller_country = normalize_country(seller_country)
    buyer_country = normalize_country(buyer_country)

    determine_treatment(
      seller_country,
      buyer_country,
      eu_member?(seller_country),
      eu_member?(buyer_country),
      b2b,
      buyer_vat_valid
    )
  end

  # Domestic sale (same country)
  defp determine_treatment(country, country, _seller_eu, _buyer_eu, _b2b, _vat_valid) do
    :domestic
  end

  # Cross-border EU B2B with valid VAT -> reverse charge
  defp determine_treatment(_seller, _buyer, true, true, true, true) do
    :reverse_charge
  end

  # Cross-border EU (B2C or invalid VAT) -> standard VAT
  defp determine_treatment(_seller, _buyer, true, true, _b2b, _vat_valid) do
    :standard
  end

  # Export outside EU (seller in EU, buyer outside)
  defp determine_treatment(_seller, _buyer, true, false, _b2b, _vat_valid) do
    :export
  end

  # Import to EU (seller outside EU, buyer in EU)
  defp determine_treatment(_seller, _buyer, false, true, _b2b, _vat_valid) do
    :import
  end

  # Both outside EU
  defp determine_treatment(_seller, _buyer, false, false, _b2b, _vat_valid) do
    :outside_eu
  end

  @doc """
  Returns the applicable VAT rate for a transaction.

  ## Examples

      # Domestic - seller's rate
      iex> ExVat.B2B.applicable_rate("SE", "SE")
      25

      # Reverse charge - 0%
      iex> ExVat.B2B.applicable_rate("SE", "DE", buyer_vat_valid: true)
      0

      # Export - 0%
      iex> ExVat.B2B.applicable_rate("SE", "US")
      0
  """
  @spec applicable_rate(String.t(), String.t(), keyword()) :: number() | nil
  def applicable_rate(seller_country, buyer_country, opts \\ []) do
    treatment = tax_treatment(seller_country, buyer_country, opts)

    case treatment do
      :domestic -> standard_rate(seller_country)
      :reverse_charge -> 0
      :standard -> standard_rate(seller_country)
      :export -> 0
      :import -> standard_rate(buyer_country)
      :outside_eu -> nil
    end
  end

  # ============================================================================
  # Transaction Checking
  # ============================================================================

  @doc """
  Validates a B2B transaction between two parties.

  Validates both VAT numbers and determines the VAT treatment for the transaction.
  Returns a `%ExVat.B2B.Transaction{}` struct with all details.

  ## Parameters

    * `seller_country` - Seller's country code
    * `seller_vat` - Seller's VAT number
    * `buyer_country` - Buyer's country code
    * `buyer_vat` - Buyer's VAT number
    * `opts` - Options:
      * `:validate_online` - Validate against VIES API (default: `true`)
      * `:b2b` - Whether this is a B2B transaction (default: `true`)
      * `:adapter` - Override the adapter for validation

  ## Returns

    * `{:ok, %Transaction{}}` - Transaction details
    * `{:error, reason}` - Validation error (atom like `:invalid_length`)

  ## Examples

      {:ok, %ExVat.B2B.Transaction{} = tx} = ExVat.B2B.validate_transaction(
        "SE", "556012345601",
        "DE", "123456789"
      )
      tx.reverse_charge   #=> true
      tx.tax_treatment    #=> :reverse_charge
      tx.vat_rate         #=> 0
      tx.invoice_note     #=> "VAT reverse charge applies..."
  """
  @spec validate_transaction(String.t(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, Transaction.t()} | {:error, atom()}
  def validate_transaction(seller_country, seller_vat, buyer_country, buyer_vat, opts \\ []) do
    validate_online = Keyword.get(opts, :validate_online, true)
    b2b = Keyword.get(opts, :b2b, true)

    seller_country_normalized = normalize_country(seller_country)
    buyer_country_normalized = normalize_country(buyer_country)

    with {:ok, seller_result} <- validate_party(seller_country_normalized, seller_vat, validate_online, opts),
         {:ok, buyer_result} <- validate_party(buyer_country_normalized, buyer_vat, validate_online, opts) do
      same = same_country?(seller_country_normalized, buyer_country_normalized)
      both_eu = eu_member?(seller_country_normalized) && eu_member?(buyer_country_normalized)
      cross_border = both_eu && !same

      treatment =
        tax_treatment(seller_country_normalized, buyer_country_normalized,
          buyer_vat_valid: buyer_result.valid,
          b2b: b2b
        )

      vat_rate = applicable_rate(
        seller_country_normalized,
        buyer_country_normalized,
        buyer_vat_valid: buyer_result.valid,
        b2b: b2b
      )

      {:ok,
       %Transaction{
         seller_country: seller_country_normalized,
         buyer_country: buyer_country_normalized,
         seller_vat: seller_vat,
         buyer_vat: buyer_vat,
         seller_valid: seller_result.valid,
         buyer_valid: buyer_result.valid,
         same_country: same,
         cross_border_eu: cross_border,
         reverse_charge: treatment == :reverse_charge,
         tax_treatment: treatment,
         vat_rate: vat_rate,
         seller_result: seller_result,
         buyer_result: buyer_result,
         invoice_note: invoice_text(treatment)
       }}
    end
  end

  @doc """
  Checks if reverse charge applies for a cross-border B2B transaction.

  ## Examples

      ExVat.B2B.reverse_charge?("SE", "556012345601", "DE", "123456789")
      #=> true

      ExVat.B2B.reverse_charge?("SE", "556012345601", "SE", "556789012301")
      #=> false
  """
  @spec reverse_charge?(String.t(), String.t(), String.t(), String.t(), keyword()) :: boolean()
  def reverse_charge?(seller_country, seller_vat, buyer_country, buyer_vat, opts \\ []) do
    case validate_transaction(seller_country, seller_vat, buyer_country, buyer_vat, opts) do
      {:ok, %Transaction{reverse_charge: true}} -> true
      _ -> false
    end
  end

  @doc """
  Checks if reverse charge applies based on countries and buyer VAT validity.

  Use this when you've already validated the VAT numbers separately.

  ## Parameters

    * `seller_country` - Seller's country code
    * `buyer_country` - Buyer's country code
    * `buyer_vat_valid?` - Whether buyer has a valid VAT number

  ## Examples

      ExVat.B2B.reverse_charge_applies?("SE", "DE", true)
      #=> true

      ExVat.B2B.reverse_charge_applies?("SE", "SE", true)
      #=> false
  """
  @spec reverse_charge_applies?(String.t(), String.t(), boolean()) :: boolean()
  def reverse_charge_applies?(seller_country, buyer_country, buyer_vat_valid?) do
    seller_country = normalize_country(seller_country)
    buyer_country = normalize_country(buyer_country)

    seller_in_eu = eu_member?(seller_country)
    buyer_in_eu = eu_member?(buyer_country)
    cross_border = !same_country?(seller_country, buyer_country)

    seller_in_eu and buyer_in_eu and cross_border and buyer_vat_valid?
  end

  @doc """
  Validates that both parties in a B2B transaction have valid VAT numbers.
  """
  @spec both_valid?(String.t(), String.t(), String.t(), String.t(), keyword()) :: boolean()
  def both_valid?(seller_country, seller_vat, buyer_country, buyer_vat, opts \\ []) do
    case validate_transaction(seller_country, seller_vat, buyer_country, buyer_vat, opts) do
      {:ok, %Transaction{seller_valid: true, buyer_valid: true}} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a transaction is within the same country.

  Handles Greece (EL/GR) normalization.
  """
  @spec same_country?(String.t(), String.t()) :: boolean()
  def same_country?(country1, country2) do
    normalize_country(country1) == normalize_country(country2)
  end

  @doc """
  Checks if a transaction is cross-border within the EU.
  """
  @spec cross_border_eu?(String.t(), String.t()) :: boolean()
  def cross_border_eu?(seller_country, buyer_country) do
    seller_country = normalize_country(seller_country)
    buyer_country = normalize_country(buyer_country)

    !same_country?(seller_country, buyer_country) &&
      eu_member?(seller_country) &&
      eu_member?(buyer_country)
  end

  # ============================================================================
  # Invoice Text
  # ============================================================================

  @doc """
  Generates invoice text for reverse charge transactions.

  ## Options

    * `:language` - Language code (default: "en")
    * `:format` - `:short` or `:long` (default: `:long`)

  ## Examples

      ExVat.B2B.reverse_charge_text()
      #=> "VAT reverse charge applies according to Article 194..."

      ExVat.B2B.reverse_charge_text(language: "de", format: :short)
      #=> "Steuerschuldnerschaft des Leistungsempfängers"
  """
  @spec reverse_charge_text(keyword()) :: String.t()
  def reverse_charge_text(opts \\ []) do
    language = Keyword.get(opts, :language, "en")
    format = Keyword.get(opts, :format, :long)

    reverse_charge_texts()[language][format] ||
      reverse_charge_texts()["en"][format]
  end

  @doc """
  Returns the invoice text for a given tax treatment.

  ## Examples

      ExVat.B2B.invoice_text(:reverse_charge)
      #=> "VAT reverse charge applies..."

      ExVat.B2B.invoice_text(:export)
      #=> "Zero-rated export outside EU"
  """
  @spec invoice_text(tax_treatment(), keyword()) :: String.t() | nil
  def invoice_text(treatment, opts \\ [])

  def invoice_text(:reverse_charge, opts), do: reverse_charge_text(opts)

  def invoice_text(:export, _opts) do
    "Zero-rated export outside EU according to EU VAT Directive"
  end

  def invoice_text(:domestic, _opts), do: nil
  def invoice_text(:standard, _opts), do: nil
  def invoice_text(:import, _opts), do: nil
  def invoice_text(:outside_eu, _opts), do: nil

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp validate_party(country, vat, true, opts) do
    ExVat.validate(country, vat, opts)
  end

  defp validate_party(country, vat, false, _opts) do
    case ExVat.validate_format(country, vat) do
      :ok ->
        {:ok,
         %ExVat.Result{
           valid: true,
           country_code: country,
           vat_number: vat,
           adapter: ExVat.Adapter.Regex
         }}

      {:error, _} = error ->
        error
    end
  end

  defp normalize_country(country) when is_binary(country) do
    upper = String.upcase(country)
    # Normalize GR to EL for consistency (Greece uses EL in VIES)
    if upper == "GR", do: "EL", else: upper
  end

  defp normalize_country(_), do: nil

  # Decimal is an optional dependency - suppress undefined function warning
  @dialyzer {:nowarn_function, maybe_decimal: 1}
  @compile {:no_warn_undefined, Decimal}
  defp maybe_decimal(rate) do
    if Code.ensure_loaded?(Decimal) and function_exported?(Decimal, :new, 1) do
      Decimal.new(rate)
    else
      rate
    end
  end

  defp reverse_charge_texts do
    %{
      "en" => %{
        short: "Reverse charge",
        long: "VAT reverse charge applies according to Article 194 of EU VAT Directive 2006/112/EC"
      },
      "de" => %{
        short: "Steuerschuldnerschaft des Leistungsempfängers",
        long: "Steuerschuldnerschaft des Leistungsempfängers gemäß Art. 194 EU-Richtlinie 2006/112/EG"
      },
      "fr" => %{
        short: "Autoliquidation de la TVA",
        long: "Autoliquidation de la TVA conformément à l'article 194 de la directive TVA 2006/112/CE"
      },
      "es" => %{
        short: "Inversión del sujeto pasivo",
        long:
          "Inversión del sujeto pasivo según el artículo 194 de la Directiva del IVA 2006/112/CE"
      },
      "it" => %{
        short: "Inversione contabile",
        long: "Inversione contabile ai sensi dell'articolo 194 della Direttiva IVA 2006/112/CE"
      },
      "nl" => %{
        short: "BTW verlegd",
        long: "BTW verlegd volgens artikel 194 van de BTW-richtlijn 2006/112/EG"
      },
      "sv" => %{
        short: "Omvänd skattskyldighet",
        long: "Omvänd skattskyldighet enligt artikel 194 i momsdirektivet 2006/112/EG"
      },
      "pl" => %{
        short: "Odwrotne obciążenie",
        long: "Odwrotne obciążenie zgodnie z art. 194 dyrektywy VAT 2006/112/WE"
      },
      "pt" => %{
        short: "Autoliquidação",
        long: "Autoliquidação nos termos do artigo 194.º da Diretiva IVA 2006/112/CE"
      },
      "da" => %{
        short: "Omvendt betalingspligt",
        long: "Omvendt betalingspligt i henhold til artikel 194 i momsdirektivet 2006/112/EF"
      },
      "fi" => %{
        short: "Käännetty verovelvollisuus",
        long: "Käännetty verovelvollisuus arvonlisäverodirektiivin 2006/112/EY artiklan 194 mukaisesti"
      }
    }
  end
end
