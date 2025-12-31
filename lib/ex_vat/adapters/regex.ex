defmodule ExVat.Adapter.Regex do
  @moduledoc """
  Offline regex-based VAT format validation adapter.

  This adapter performs local validation of VAT number formats using regex patterns.
  It does NOT verify that VAT numbers actually exist in any database.

  ## Use Cases

    * Quick client-side validation before API calls
    * Fallback when VIES API is unavailable
    * Offline applications
    * Reducing unnecessary API calls for obviously invalid inputs

  ## Limitations

    * Cannot verify if a VAT number is actually registered
    * Cannot provide company name/address information
    * Does not support trader matching

  ## Configuration

      config :ex_vat,
        adapter: ExVat.Adapter.Regex

  Or use as fallback:

      config :ex_vat,
        adapter: ExVat.Adapter.Vies,
        fallback_adapter: ExVat.Adapter.Regex
  """

  @behaviour ExVat.Adapter

  alias ExVat.{Format, Result}

  @impl ExVat.Adapter
  def validate(country_code, vat_number, _opts \\ []) do
    case Format.validate_and_normalize(country_code, vat_number) do
      {:ok, normalized_country, normalized_vat} ->
        result = %Result{
          valid: true,
          country_code: normalized_country,
          vat_number: normalized_vat,
          request_date: DateTime.utc_now(),
          adapter: __MODULE__,
          country_name: Format.country_name(normalized_country)
        }

        {:ok, result}

      {:error, reason} ->
        {:ok,
         %Result{
           valid: false,
           country_code: String.upcase(to_string(country_code)),
           vat_number: to_string(vat_number),
           request_date: DateTime.utc_now(),
           adapter: __MODULE__,
           raw_response: %{error: reason}
         }}
    end
  end

  @impl ExVat.Adapter
  def validate_format(country_code, vat_number) do
    Format.validate(country_code, vat_number)
  end

  @impl ExVat.Adapter
  def check_status do
    # Regex adapter is always available
    countries =
      Format.country_codes()
      |> Enum.map(fn code -> %{country_code: code, available: true} end)

    {:ok, %{available: true, countries: countries}}
  end

  @impl ExVat.Adapter
  def supports_country?(country_code) do
    Format.valid_country_code?(country_code)
  end

  @impl ExVat.Adapter
  def capabilities do
    [:validate, :validate_format, :check_status]
  end
end
