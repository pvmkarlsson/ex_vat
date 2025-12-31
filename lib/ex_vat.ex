defmodule ExVat do
  @moduledoc """
  A flexible EU VAT validation library with pluggable adapters.

  ExVat provides a unified interface for validating EU VAT numbers using
  different backends (adapters). The default adapter uses the official EU VIES
  API, but you can also use offline regex validation or implement custom adapters.

  ## Quick Start

      # Simple validation (uses configured adapter, defaults to VIES)
      {:ok, result} = ExVat.validate("SE", "556012345601")

      # Check if valid
      result.valid  #=> true

      # Get company info (VIES adapter only)
      result.name     #=> "COMPANY AB"
      result.address  #=> "STREET 1, 123 45 CITY"

  ## Configuration

      # config/config.exs
      config :ex_vat,
        adapter: ExVat.Adapter.Vies,
        fallback_adapter: ExVat.Adapter.Regex

      # Adapter-specific config
      config :ex_vat, ExVat.Adapter.Vies,
        timeout: 30_000,
        max_retries: 3

  ## Available Adapters

    * `ExVat.Adapter.Vies` - Official EU VIES API (default)
    * `ExVat.Adapter.Regex` - Offline format validation only

  ## Features

    * Multiple adapter backends
    * Automatic fallback on failure
    * Input normalization (removes spaces, dashes, country prefixes)
    * Format validation before API calls
    * Retry logic with exponential backoff (VIES adapter)
    * Company information lookup (VIES adapter)
    * Trader matching (VIES adapter)
    * B2B cross-border VAT calculations
  """

  alias ExVat.{Adapter, Error, Format, Result}

  @type validate_opts :: [
          adapter: module(),
          fallback: boolean(),
          normalize: boolean(),
          strict: boolean(),
          test_mode: boolean(),
          requester_member_state_code: String.t(),
          requester_number: String.t(),
          trader_name: String.t(),
          trader_street: String.t(),
          trader_postal_code: String.t(),
          trader_city: String.t(),
          trader_company_type: String.t()
        ]

  @doc """
  Validates a VAT number using the configured adapter.

  ## Parameters

    * `country_code` - Two-letter EU country code (e.g., "SE", "DE", "FR")
    * `vat_number` - The VAT number to validate
    * `opts` - Options:
      * `:adapter` - Override the configured adapter
      * `:fallback` - Use fallback adapter on failure (default: `true`)
      * `:normalize` - Normalize input (default: `true`)
      * `:strict` - Validate format before API call (default: `false`)
      * `:test_mode` - Use VIES test endpoint (default: `false`)
      * Trader matching options (VIES only)

  ## Returns

    * `{:ok, %ExVat.Result{}}` - Validation result
    * `{:error, %ExVat.Error{}}` - Error

  ## Examples

      # Simple validation
      {:ok, result} = ExVat.validate("SE", "556012345601")
      result.valid  #=> true or false

      # With company info
      {:ok, result} = ExVat.validate("DE", "123456789")
      result.name     #=> "COMPANY GMBH"
      result.address  #=> "STRASSE 1, 12345 BERLIN"

      # With request identifier (for audit trail)
      {:ok, result} = ExVat.validate("FR", "12345678901",
        requester_member_state_code: "SE",
        requester_number: "556012345601"
      )
      result.request_identifier  #=> "WAPIAAAAW..."

      # Strict mode (validates format first)
      {:ok, result} = ExVat.validate("SE", "123", strict: true)
      #=> {:error, %ExVat.Error{code: "INVALID_LENGTH"}}

      # Using specific adapter
      {:ok, result} = ExVat.validate("SE", "556012345601",
        adapter: ExVat.Adapter.Regex
      )
  """
  @spec validate(String.t(), String.t(), validate_opts()) ::
          {:ok, Result.t()} | {:error, Error.t() | term()}
  def validate(country_code, vat_number, opts \\ []) do
    adapter = Keyword.get(opts, :adapter, Adapter.adapter())
    use_fallback = Keyword.get(opts, :fallback, true)
    normalize = Keyword.get(opts, :normalize, true)
    strict = Keyword.get(opts, :strict, false)

    with {:ok, country_code, vat_number} <- prepare_input(country_code, vat_number, normalize, strict) do
      case adapter.validate(country_code, vat_number, opts) do
        {:ok, result} ->
          {:ok, result}

        {:error, error} when use_fallback ->
          maybe_fallback(error, country_code, vat_number, opts)

        {:error, error} ->
          {:error, error}
      end
    end
  end

  @doc """
  Validates a VAT number and raises on error.

  Same as `validate/3` but raises `ExVat.Error` on failure.

  ## Examples

      result = ExVat.validate!("SE", "556012345601")
      result.valid  #=> true

      ExVat.validate!("XX", "invalid")
      #=> raises ExVat.Error
  """
  @spec validate!(String.t(), String.t(), validate_opts()) :: Result.t()
  def validate!(country_code, vat_number, opts \\ []) do
    case validate(country_code, vat_number, opts) do
      {:ok, result} ->
        result

      {:error, %Error{} = error} ->
        raise error

      {:error, :invalid_country_code} ->
        raise Error.invalid_country_code(country_code)

      {:error, :invalid_format} ->
        raise Error.invalid_format(country_code, vat_number)

      {:error, :invalid_length} ->
        raise Error.invalid_length(country_code, vat_number)

      {:error, reason} ->
        raise Error.from_http_error(reason, Adapter.adapter())
    end
  end

  @doc """
  Validates only the format of a VAT number (no API call).

  This is a quick local validation using regex patterns.
  Use this to reject obviously invalid numbers before making API calls.

  ## Examples

      ExVat.validate_format("SE", "556012345601")
      #=> :ok

      ExVat.validate_format("SE", "123")
      #=> {:error, :invalid_length}
  """
  @spec validate_format(String.t(), String.t()) ::
          :ok | {:error, :invalid_country_code | :invalid_format | :invalid_length}
  defdelegate validate_format(country_code, vat_number), to: Format, as: :validate

  @doc """
  Checks if a VAT number has valid format.

  ## Examples

      ExVat.valid_format?("SE", "556012345601")
      #=> true

      ExVat.valid_format?("SE", "123")
      #=> false
  """
  @spec valid_format?(String.t(), String.t()) :: boolean()
  defdelegate valid_format?(country_code, vat_number), to: Format

  @doc """
  Checks the status of the VAT validation service.

  ## Examples

      {:ok, status} = ExVat.check_status()
      status.available  #=> true
      status.countries  #=> [%{country_code: "SE", available: true}, ...]
  """
  @spec check_status(keyword()) :: {:ok, map()} | {:error, term()}
  def check_status(opts \\ []) do
    adapter = Keyword.get(opts, :adapter, Adapter.adapter())
    adapter.check_status()
  end

  @doc """
  Checks if a specific country's VAT service is available.

  ## Examples

      ExVat.country_available?("SE")
      #=> true
  """
  @spec country_available?(String.t(), keyword()) :: boolean()
  def country_available?(country_code, opts \\ []) do
    case check_status(opts) do
      {:ok, %{countries: countries}} ->
        code = String.upcase(country_code)
        Enum.any?(countries, &(&1.country_code == code && &1.available))

      {:error, _} ->
        false
    end
  end

  @doc """
  Returns a list of all supported EU country codes.

  ## Examples

      ExVat.country_codes()
      #=> ["AT", "BE", "BG", ...]
  """
  @spec country_codes() :: [String.t()]
  defdelegate country_codes(), to: Format

  @doc """
  Returns the country name for a given code.

  ## Examples

      ExVat.country_name("SE")
      #=> "Sweden"
  """
  @spec country_name(String.t()) :: String.t() | nil
  defdelegate country_name(code), to: Format

  @doc """
  Returns all country codes with their names.

  ## Examples

      ExVat.countries()
      #=> %{"SE" => "Sweden", "DE" => "Germany", ...}
  """
  @spec countries() :: %{String.t() => String.t()}
  defdelegate countries(), to: Format

  @doc """
  Normalizes a VAT number by removing formatting characters.

  ## Examples

      ExVat.normalize("SE", "SE 556-012.345 601")
      #=> {:ok, "SE", "556012345601"}
  """
  @spec normalize(String.t(), String.t()) ::
          {:ok, String.t(), String.t()} | {:error, atom()}
  defdelegate normalize(country_code, vat_number), to: Format

  @doc """
  Extracts country code from a VAT number with prefix.

  ## Examples

      ExVat.extract_country_code("SE556012345601")
      #=> {:ok, "SE", "556012345601"}
  """
  @spec extract_country_code(String.t()) ::
          {:ok, String.t(), String.t()} | {:error, atom()}
  defdelegate extract_country_code(full_vat_number), to: Format

  @doc """
  Checks if a country code is a valid EU member state.

  ## Examples

      ExVat.valid_country_code?("SE")
      #=> true

      ExVat.valid_country_code?("US")
      #=> false
  """
  @spec valid_country_code?(String.t()) :: boolean()
  defdelegate valid_country_code?(code), to: Format

  # Private helpers

  defp prepare_input(country_code, vat_number, true = _normalize, strict) do
    case Format.normalize(country_code, vat_number) do
      {:ok, cc, vn} -> maybe_validate_strict(cc, vn, strict)
      error -> error
    end
  end

  defp prepare_input(country_code, vat_number, false = _normalize, strict) do
    case Format.validate_country_code(country_code) do
      :ok -> maybe_validate_strict(String.upcase(country_code), vat_number, strict)
      error -> error
    end
  end

  defp maybe_validate_strict(country_code, vat_number, true = _strict) do
    case Format.validate(country_code, vat_number) do
      :ok -> {:ok, country_code, vat_number}
      error -> error
    end
  end

  defp maybe_validate_strict(country_code, vat_number, false = _strict) do
    {:ok, country_code, vat_number}
  end

  defp maybe_fallback(error, country_code, vat_number, opts) do
    fallback = Adapter.fallback_adapter()

    if fallback && Error.retryable?(error) do
      case fallback.validate(country_code, vat_number, opts) do
        {:ok, result} ->
          {:ok, %{result | raw_response: Map.put(result.raw_response || %{}, :fallback_used, true)}}

        {:error, _} ->
          {:error, error}
      end
    else
      {:error, error}
    end
  end
end
