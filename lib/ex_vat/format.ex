defmodule ExVat.Format do
  @moduledoc """
  VAT number format validation and normalization utilities.

  This module provides functions to validate and normalize VAT numbers.
  It implements country-specific format validation using regex patterns
  and handles common input preprocessing (removing spaces, dashes, etc.).

  ## Supported Countries

  All EU member states plus Northern Ireland are supported:
  AT, BE, BG, CY, CZ, DE, DK, EE, EL, ES, FI, FR, HR, HU, IE, IT,
  LT, LU, LV, MT, NL, PL, PT, RO, SE, SI, SK, XI

  ## Examples

      iex> ExVat.Format.normalize("SE", "SE 5560-1234.5601")
      {:ok, "SE", "556012345601"}

      iex> ExVat.Format.validate("DE", "123456789")
      :ok

      iex> ExVat.Format.validate("DE", "12345")
      {:error, :invalid_length}
  """

  @eu_country_codes ~w(AT BE BG CY CZ DE DK EE EL ES FI FR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK XI)

  @country_names %{
    "AT" => "Austria",
    "BE" => "Belgium",
    "BG" => "Bulgaria",
    "CY" => "Cyprus",
    "CZ" => "Czech Republic",
    "DE" => "Germany",
    "DK" => "Denmark",
    "EE" => "Estonia",
    "EL" => "Greece",
    "ES" => "Spain",
    "FI" => "Finland",
    "FR" => "France",
    "HR" => "Croatia",
    "HU" => "Hungary",
    "IE" => "Ireland",
    "IT" => "Italy",
    "LT" => "Lithuania",
    "LU" => "Luxembourg",
    "LV" => "Latvia",
    "MT" => "Malta",
    "NL" => "Netherlands",
    "PL" => "Poland",
    "PT" => "Portugal",
    "RO" => "Romania",
    "SE" => "Sweden",
    "SI" => "Slovenia",
    "SK" => "Slovakia",
    "XI" => "Northern Ireland"
  }

  # VAT number format patterns per country
  # Format: {min_length, max_length, regex_pattern}
  @vat_formats %{
    "AT" => {9, 9, ~r/^U\d{8}$/},
    "BE" => {10, 10, ~r/^[01]\d{9}$/},
    "BG" => {9, 10, ~r/^\d{9,10}$/},
    "CY" => {9, 9, ~r/^\d{8}[A-Z]$/},
    "CZ" => {8, 10, ~r/^\d{8,10}$/},
    "DE" => {9, 9, ~r/^\d{9}$/},
    "DK" => {8, 8, ~r/^\d{8}$/},
    "EE" => {9, 9, ~r/^\d{9}$/},
    "EL" => {9, 9, ~r/^\d{9}$/},
    "ES" => {9, 9, ~r/^[A-Z0-9]\d{7}[A-Z0-9]$/},
    "FI" => {8, 8, ~r/^\d{8}$/},
    "FR" => {11, 11, ~r/^[A-Z0-9]{2}\d{9}$/},
    "HR" => {11, 11, ~r/^\d{11}$/},
    "HU" => {8, 8, ~r/^\d{8}$/},
    "IE" => {8, 9, ~r/^(\d{7}[A-Z]{1,2}|\d[A-Z+*]\d{5}[A-Z])$/},
    "IT" => {11, 11, ~r/^\d{11}$/},
    "LT" => {9, 12, ~r/^(\d{9}|\d{12})$/},
    "LU" => {8, 8, ~r/^\d{8}$/},
    "LV" => {11, 11, ~r/^\d{11}$/},
    "MT" => {8, 8, ~r/^\d{8}$/},
    "NL" => {12, 12, ~r/^\d{9}B\d{2}$/},
    "PL" => {10, 10, ~r/^\d{10}$/},
    "PT" => {9, 9, ~r/^\d{9}$/},
    "RO" => {2, 10, ~r/^\d{2,10}$/},
    "SE" => {12, 12, ~r/^\d{12}$/},
    "SI" => {8, 8, ~r/^\d{8}$/},
    "SK" => {10, 10, ~r/^\d{10}$/},
    "XI" => {9, 12, ~r/^(\d{9}|\d{12}|GD\d{3}|HA\d{3})$/}
  }

  @doc """
  Returns a list of all supported EU country codes.
  """
  @spec country_codes() :: [String.t()]
  def country_codes, do: @eu_country_codes

  @doc """
  Returns the full country name for a given country code.
  """
  @spec country_name(String.t()) :: String.t() | nil
  def country_name(code) when is_binary(code) do
    Map.get(@country_names, String.upcase(code))
  end

  def country_name(_), do: nil

  @doc """
  Returns all country codes with their names.
  """
  @spec countries() :: %{String.t() => String.t()}
  def countries, do: @country_names

  @doc """
  Validates that a country code is a supported EU member state.

  ## Examples

      iex> ExVat.Format.validate_country_code("SE")
      :ok

      iex> ExVat.Format.validate_country_code("US")
      {:error, :invalid_country_code}
  """
  @spec validate_country_code(String.t()) :: :ok | {:error, :invalid_country_code}
  def validate_country_code(code) when is_binary(code) do
    if String.upcase(code) in @eu_country_codes do
      :ok
    else
      {:error, :invalid_country_code}
    end
  end

  def validate_country_code(_), do: {:error, :invalid_country_code}

  @doc """
  Checks if a country code is a valid EU member state.
  """
  @spec valid_country_code?(String.t()) :: boolean()
  def valid_country_code?(code) when is_binary(code) do
    String.upcase(code) in @eu_country_codes
  end

  def valid_country_code?(_), do: false

  @doc """
  Normalizes a VAT number by removing common formatting characters.

  Removes spaces, dashes, dots, and optionally the country prefix.

  ## Examples

      iex> ExVat.Format.normalize_vat_number("SE", "SE 556-012.345 601")
      "556012345601"

      iex> ExVat.Format.normalize_vat_number("DE", "DE123456789")
      "123456789"
  """
  @spec normalize_vat_number(String.t(), String.t()) :: String.t()
  def normalize_vat_number(country_code, vat_number)
      when is_binary(country_code) and is_binary(vat_number) do
    country_code = String.upcase(country_code)

    vat_number
    |> String.upcase()
    |> String.replace(~r/[\s\-\.]+/, "")
    |> strip_country_prefix(country_code)
  end

  @doc """
  Normalizes both country code and VAT number, returning the cleaned values.

  ## Examples

      iex> ExVat.Format.normalize("se", "SE 556-012.345 601")
      {:ok, "SE", "556012345601"}

      iex> ExVat.Format.normalize("XX", "123")
      {:error, :invalid_country_code}
  """
  @spec normalize(String.t(), String.t()) ::
          {:ok, String.t(), String.t()} | {:error, :invalid_country_code | :empty_vat_number}
  def normalize(country_code, vat_number) when is_binary(country_code) and is_binary(vat_number) do
    country_code = String.upcase(String.trim(country_code))

    case validate_country_code(country_code) do
      :ok ->
        normalized_vat = normalize_vat_number(country_code, vat_number)

        if normalized_vat == "" do
          {:error, :empty_vat_number}
        else
          {:ok, country_code, normalized_vat}
        end

      error ->
        error
    end
  end

  def normalize(_, _), do: {:error, :invalid_country_code}

  @doc """
  Validates the format of a VAT number for a specific country.

  Note: This only validates the format, not whether the VAT number actually exists.

  ## Examples

      iex> ExVat.Format.validate("SE", "556012345601")
      :ok

      iex> ExVat.Format.validate("SE", "123")
      {:error, :invalid_length}
  """
  @spec validate(String.t(), String.t()) ::
          :ok | {:error, :invalid_country_code | :invalid_format | :invalid_length}
  def validate(country_code, vat_number) when is_binary(country_code) and is_binary(vat_number) do
    country_code = String.upcase(country_code)

    with :ok <- validate_country_code(country_code),
         {:ok, {min_len, max_len, pattern}} <- get_format(country_code),
         :ok <- validate_length(vat_number, min_len, max_len) do
      validate_pattern(vat_number, pattern)
    end
  end

  def validate(_, _), do: {:error, :invalid_country_code}

  @doc """
  Performs full validation: normalizes the input and validates the format.

  Returns the normalized country code and VAT number if valid.

  ## Examples

      iex> ExVat.Format.validate_and_normalize("SE", "SE 556-012.345 601")
      {:ok, "SE", "556012345601"}

      iex> ExVat.Format.validate_and_normalize("SE", "123")
      {:error, :invalid_length}
  """
  @spec validate_and_normalize(String.t(), String.t()) ::
          {:ok, String.t(), String.t()}
          | {:error, :invalid_country_code | :empty_vat_number | :invalid_format | :invalid_length}
  def validate_and_normalize(country_code, vat_number) do
    with {:ok, country_code, normalized_vat} <- normalize(country_code, vat_number),
         :ok <- validate(country_code, normalized_vat) do
      {:ok, country_code, normalized_vat}
    end
  end

  @doc """
  Checks if a VAT number has valid format.
  """
  @spec valid_format?(String.t(), String.t()) :: boolean()
  def valid_format?(country_code, vat_number) do
    case validate_and_normalize(country_code, vat_number) do
      {:ok, _, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Extracts the country code from a VAT number that includes it as a prefix.

  ## Examples

      iex> ExVat.Format.extract_country_code("SE556012345601")
      {:ok, "SE", "556012345601"}

      iex> ExVat.Format.extract_country_code("XX123456")
      {:error, :invalid_country_code}

      iex> ExVat.Format.extract_country_code("123456")
      {:error, :no_country_prefix}
  """
  @spec extract_country_code(String.t()) ::
          {:ok, String.t(), String.t()} | {:error, :invalid_country_code | :no_country_prefix}
  def extract_country_code(full_vat_number) when is_binary(full_vat_number) do
    cleaned = full_vat_number |> String.upcase() |> String.replace(~r/[\s\-\.]+/, "")

    if String.length(cleaned) < 3 do
      {:error, :no_country_prefix}
    else
      prefix = String.slice(cleaned, 0, 2)
      rest = String.slice(cleaned, 2..-1//1)

      if prefix in @eu_country_codes do
        {:ok, prefix, rest}
      else
        {:error, :invalid_country_code}
      end
    end
  end

  def extract_country_code(_), do: {:error, :no_country_prefix}

  @doc """
  Returns the expected VAT format information for a country.

  Returns `{min_length, max_length, pattern}` or `nil` if not found.
  """
  @spec format_info(String.t()) :: {pos_integer(), pos_integer(), Regex.t()} | nil
  def format_info(country_code) when is_binary(country_code) do
    Map.get(@vat_formats, String.upcase(country_code))
  end

  def format_info(_), do: nil

  # Private helpers

  defp strip_country_prefix(vat_number, country_code) do
    prefix_len = String.length(country_code)

    if String.starts_with?(vat_number, country_code) do
      String.slice(vat_number, prefix_len..-1//1)
    else
      # Handle GR -> EL mapping for Greece
      if country_code == "EL" and String.starts_with?(vat_number, "GR") do
        String.slice(vat_number, 2..-1//1)
      else
        vat_number
      end
    end
  end

  defp get_format(country_code) do
    case Map.get(@vat_formats, country_code) do
      nil -> {:error, :invalid_country_code}
      format -> {:ok, format}
    end
  end

  defp validate_length(vat_number, min_len, max_len) do
    len = String.length(vat_number)

    if len >= min_len and len <= max_len do
      :ok
    else
      {:error, :invalid_length}
    end
  end

  defp validate_pattern(vat_number, pattern) do
    if Regex.match?(pattern, vat_number) do
      :ok
    else
      {:error, :invalid_format}
    end
  end
end
