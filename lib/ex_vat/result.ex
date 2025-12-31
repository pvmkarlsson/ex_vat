defmodule ExVat.Result do
  @moduledoc """
  Unified result structure for VAT validation.

  This struct provides a consistent interface for validation results regardless
  of which adapter performed the validation.

  ## Fields

  ### Core Fields

    * `:valid` - Whether the VAT number is valid
    * `:country_code` - The country code that was validated
    * `:vat_number` - The VAT number that was validated
    * `:request_date` - When the validation was performed
    * `:adapter` - Which adapter performed the validation

  ### Company Information (API adapters only)

    * `:name` - Registered company name
    * `:address` - Registered company address
    * `:country_name` - Full country name

  ### Request Tracking (VIES adapter)

    * `:request_identifier` - Unique identifier for audit trail

  ### Corrections (VIES adapter)

    * `:corrected` - Whether the VAT number was corrected
    * `:original_vat_number` - Original VAT number before correction
    * `:correction_message` - Description of the correction applied

  ### Trader Matching (VIES adapter)

    * `:trader_name_match` - Match result for name (:valid | :invalid | :not_processed)
    * `:trader_street_match` - Match result for street
    * `:trader_postal_code_match` - Match result for postal code
    * `:trader_city_match` - Match result for city
    * `:trader_company_type_match` - Match result for company type

  ## Examples

      # Simple validation result
      %ExVat.Result{
        valid: true,
        country_code: "SE",
        vat_number: "556012345601",
        adapter: ExVat.Adapter.Vies
      }

      # Full result with company info
      %ExVat.Result{
        valid: true,
        country_code: "SE",
        vat_number: "556012345601",
        name: "COMPANY AB",
        address: "STREET 1, 123 45 CITY",
        request_identifier: "WAPIAAAAW...",
        adapter: ExVat.Adapter.Vies
      }
  """

  @type match_result :: :valid | :invalid | :not_processed | nil

  @type t :: %__MODULE__{
          # Core fields
          valid: boolean() | nil,
          country_code: String.t() | nil,
          vat_number: String.t() | nil,
          request_date: DateTime.t() | nil,
          adapter: module() | nil,

          # Company information
          name: String.t() | nil,
          address: String.t() | nil,
          country_name: String.t() | nil,

          # Request tracking
          request_identifier: String.t() | nil,

          # Corrections
          corrected: boolean(),
          original_vat_number: String.t() | nil,
          correction_message: String.t() | nil,

          # Trader matching
          trader_name_match: match_result(),
          trader_street_match: match_result(),
          trader_postal_code_match: match_result(),
          trader_city_match: match_result(),
          trader_company_type_match: match_result(),

          # Metadata
          raw_response: map() | nil
        }

  defstruct valid: nil,
            country_code: nil,
            vat_number: nil,
            request_date: nil,
            adapter: nil,
            name: nil,
            address: nil,
            country_name: nil,
            request_identifier: nil,
            corrected: false,
            original_vat_number: nil,
            correction_message: nil,
            trader_name_match: nil,
            trader_street_match: nil,
            trader_postal_code_match: nil,
            trader_city_match: nil,
            trader_company_type_match: nil,
            raw_response: nil

  @doc """
  Returns true if the VAT number was corrected by the validation service.
  """
  @spec corrected?(t()) :: boolean()
  def corrected?(%__MODULE__{corrected: true}), do: true
  def corrected?(%__MODULE__{}), do: false

  @doc """
  Returns true if all provided trader fields matched.

  Fields that were not checked (nil) are ignored.
  """
  @spec all_trader_fields_match?(t()) :: boolean()
  def all_trader_fields_match?(%__MODULE__{} = result) do
    match_fields = [
      result.trader_name_match,
      result.trader_street_match,
      result.trader_postal_code_match,
      result.trader_city_match,
      result.trader_company_type_match
    ]

    provided_matches = Enum.reject(match_fields, &is_nil/1)

    if Enum.empty?(provided_matches) do
      true
    else
      Enum.all?(provided_matches, &(&1 == :valid))
    end
  end

  @doc """
  Returns true if any provided trader field did not match.
  """
  @spec any_trader_field_invalid?(t()) :: boolean()
  def any_trader_field_invalid?(%__MODULE__{} = result) do
    match_fields = [
      result.trader_name_match,
      result.trader_street_match,
      result.trader_postal_code_match,
      result.trader_city_match,
      result.trader_company_type_match
    ]

    Enum.any?(match_fields, &(&1 == :invalid))
  end

  @doc """
  Creates a simple valid result for format-only validation.
  """
  @spec format_valid(String.t(), String.t(), module()) :: t()
  def format_valid(country_code, vat_number, adapter) do
    %__MODULE__{
      valid: true,
      country_code: country_code,
      vat_number: vat_number,
      request_date: DateTime.utc_now(),
      adapter: adapter
    }
  end

  @doc """
  Creates a simple invalid result.
  """
  @spec invalid(String.t(), String.t(), module()) :: t()
  def invalid(country_code, vat_number, adapter) do
    %__MODULE__{
      valid: false,
      country_code: country_code,
      vat_number: vat_number,
      request_date: DateTime.utc_now(),
      adapter: adapter
    }
  end
end
