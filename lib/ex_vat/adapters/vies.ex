defmodule ExVat.Adapter.Vies do
  @moduledoc """
  VIES (VAT Information Exchange System) adapter for EU VAT validation.

  This adapter provides full integration with the official EU VIES API for
  validating VAT numbers across all EU member states.

  ## Features

    * Real-time VAT validation against the VIES database
    * Company name and address lookup
    * Trader information approximate matching
    * Request identifiers for audit trails
    * Automatic retry with exponential backoff
    * Member state availability checking

  ## Configuration

      config :ex_vat, ExVat.Adapter.Vies,
        base_url: "https://ec.europa.eu/taxation_customs/vies/rest-api",
        timeout: 30_000,
        recv_timeout: 15_000,
        max_retries: 3,
        retry_delay: 1_000,
        retry_backoff: :exponential

  ## Test Endpoint

  For integration testing, you can use the test endpoint:

      # Returns VALID
      ExVat.validate("SE", "100", adapter: ExVat.Adapter.Vies, test_mode: true)

      # Returns INVALID
      ExVat.validate("SE", "200", adapter: ExVat.Adapter.Vies, test_mode: true)
  """

  @behaviour ExVat.Adapter

  require Logger

  alias ExVat.{Error, Format, Result}

  @default_base_url "https://ec.europa.eu/taxation_customs/vies/rest-api"
  @default_timeout 30_000
  @default_recv_timeout 15_000
  @default_max_retries 3
  @default_retry_delay 1_000

  @retryable_errors [:timeout, :econnrefused, :closed, :ehostunreach, :enetunreach]

  @impl ExVat.Adapter
  def validate(country_code, vat_number, opts \\ []) do
    test_mode = Keyword.get(opts, :test_mode, false)

    body = build_request_body(country_code, vat_number, opts)
    endpoint = if test_mode, do: "/check-vat-test-service", else: "/check-vat-number"

    case post_with_retry(endpoint, body, opts) do
      {:ok, %{status: 200, body: response_body}} ->
        {:ok, parse_check_vat_response(response_body, country_code, vat_number)}

      {:ok, %{status: status, body: response_body}} when status in [400, 500] ->
        {:error, parse_error_response(response_body)}

      {:ok, %{status: 403, body: response_body}} ->
        {:error, parse_error_response(response_body, "FORBIDDEN", "Access forbidden")}

      {:ok, %{status: 429}} ->
        {:error, Error.from_api_response("RATE_LIMITED", "Too many requests", __MODULE__)}

      {:ok, %{status: status}} ->
        {:error, Error.from_http_error({:unexpected_status, status}, __MODULE__)}

      {:error, reason} ->
        {:error, Error.from_http_error(reason, __MODULE__)}
    end
  end

  @impl ExVat.Adapter
  def validate_format(country_code, vat_number) do
    Format.validate(country_code, vat_number)
  end

  @impl ExVat.Adapter
  def check_status do
    case get_with_retry("/check-status") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_status_response(body)}

      {:ok, %{status: status, body: body}} when status in [400, 500] ->
        {:error, parse_error_response(body)}

      {:ok, %{status: status}} ->
        {:error, Error.from_http_error({:unexpected_status, status}, __MODULE__)}

      {:error, reason} ->
        {:error, Error.from_http_error(reason, __MODULE__)}
    end
  end

  @impl ExVat.Adapter
  def supports_country?(country_code) do
    Format.valid_country_code?(country_code)
  end

  @impl ExVat.Adapter
  def capabilities do
    [:validate, :validate_format, :check_status, :trader_matching, :request_identifier]
  end

  # Request building

  defp build_request_body(country_code, vat_number, opts) do
    %{
      "countryCode" => String.upcase(country_code),
      "vatNumber" => vat_number
    }
    |> maybe_put("requesterMemberStateCode", opts[:requester_member_state_code])
    |> maybe_put("requesterNumber", opts[:requester_number])
    |> maybe_put("traderName", opts[:trader_name])
    |> maybe_put("traderStreet", opts[:trader_street])
    |> maybe_put("traderPostalCode", opts[:trader_postal_code])
    |> maybe_put("traderCity", opts[:trader_city])
    |> maybe_put("traderCompanyType", opts[:trader_company_type])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # Response parsing

  defp parse_check_vat_response(json, _country_code, _vat_number) when is_map(json) do
    %Result{
      valid: json["valid"],
      country_code: json["countryCode"],
      vat_number: json["vatNumber"],
      request_date: parse_datetime(json["requestDate"]),
      adapter: __MODULE__,
      name: json["name"],
      address: json["address"],
      country_name: Format.country_name(json["countryCode"]),
      request_identifier: json["requestIdentifier"],
      corrected: json["vatNumberCorrected"] == true,
      original_vat_number: if(json["vatNumberCorrected"], do: json["vatNumber"]),
      correction_message: json["userError"],
      trader_name_match: parse_match(json["traderNameMatch"]),
      trader_street_match: parse_match(json["traderStreetMatch"]),
      trader_postal_code_match: parse_match(json["traderPostalCodeMatch"]),
      trader_city_match: parse_match(json["traderCityMatch"]),
      trader_company_type_match: parse_match(json["traderCompanyTypeMatch"]),
      raw_response: json
    }
  end

  defp parse_status_response(json) when is_map(json) do
    countries =
      json
      |> Map.get("countries", [])
      |> Enum.map(fn c ->
        %{
          country_code: c["countryCode"],
          available: c["availability"] == "Available"
        }
      end)

    %{
      available: get_in(json, ["vow", "available"]) || false,
      countries: countries
    }
  end

  defp parse_error_response(json, default_code \\ nil, default_message \\ nil) do
    error_wrapper =
      json
      |> Map.get("errorWrappers", [])
      |> List.first()

    code = (error_wrapper && error_wrapper["error"]) || json["error"] || default_code
    message = (error_wrapper && error_wrapper["message"]) || json["message"] || default_message

    Error.from_api_response(code, message, __MODULE__)
  end

  defp parse_match(nil), do: nil
  defp parse_match("VALID"), do: :valid
  defp parse_match("INVALID"), do: :invalid
  defp parse_match("NOT_PROCESSED"), do: :not_processed
  defp parse_match(_), do: nil

  defp parse_datetime(nil), do: nil

  defp parse_datetime(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} ->
        datetime

      {:error, _} ->
        case NaiveDateTime.from_iso8601(date_string) do
          {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
          {:error, _} -> nil
        end
    end
  end

  # HTTP helpers with retry

  defp post_with_retry(path, body, opts, attempt \\ 0) do
    max_retries = config(:max_retries, @default_max_retries)

    case do_post(path, body, opts) do
      {:ok, %{status: status} = response} when status in 200..499 ->
        {:ok, response}

      {:ok, %{status: status}} when status >= 500 and attempt < max_retries ->
        log_retry(path, "HTTP #{status}", attempt, max_retries)
        wait_before_retry(attempt)
        post_with_retry(path, body, opts, attempt + 1)

      {:ok, response} ->
        {:ok, response}

      {:error, reason} when reason in @retryable_errors and attempt < max_retries ->
        log_retry(path, reason, attempt, max_retries)
        wait_before_retry(attempt)
        post_with_retry(path, body, opts, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_with_retry(path, attempt \\ 0) do
    max_retries = config(:max_retries, @default_max_retries)

    case do_get(path) do
      {:ok, %{status: status} = response} when status in 200..499 ->
        {:ok, response}

      {:ok, %{status: status}} when status >= 500 and attempt < max_retries ->
        log_retry(path, "HTTP #{status}", attempt, max_retries)
        wait_before_retry(attempt)
        get_with_retry(path, attempt + 1)

      {:ok, response} ->
        {:ok, response}

      {:error, reason} when reason in @retryable_errors and attempt < max_retries ->
        log_retry(path, reason, attempt, max_retries)
        wait_before_retry(attempt)
        get_with_retry(path, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_post(path, body, _opts) do
    url = base_url() <> path
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    encoded_body = JSON.encode!(body)

    case http_client().post(url, encoded_body, headers, http_options()) do
      {:ok, %{status_code: status, body: response_body}} ->
        {:ok, %{status: status, body: decode_body(response_body)}}

      {:error, %{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_get(path) do
    url = base_url() <> path
    headers = [{"accept", "application/json"}]

    case http_client().get(url, headers, http_options()) do
      {:ok, %{status_code: status, body: response_body}} ->
        {:ok, %{status: status, body: decode_body(response_body)}}

      {:error, %{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode_body(""), do: %{}

  defp decode_body(body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, decoded} ->
        decoded

      {:error, error} ->
        Logger.warning("Failed to decode VIES response: #{inspect(error)}")
        %{"errorWrappers" => [%{"error" => "PARSE_ERROR", "message" => "Invalid JSON response"}]}
    end
  end

  defp wait_before_retry(attempt) do
    delay = calculate_retry_delay(attempt)
    Process.sleep(delay)
  end

  defp calculate_retry_delay(attempt) do
    base_delay = config(:retry_delay, @default_retry_delay)
    backoff = config(:retry_backoff, :exponential)

    case backoff do
      :constant -> base_delay
      :exponential -> trunc(base_delay * :math.pow(2, attempt))
      :jittered -> :rand.uniform(trunc(base_delay * :math.pow(2, attempt)))
      _ -> base_delay
    end
  end

  defp log_retry(path, reason, attempt, max_retries) do
    Logger.info(
      "[ExVat.Adapter.Vies] Request to #{path} failed (#{inspect(reason)}), " <>
        "retrying (#{attempt + 1}/#{max_retries})"
    )
  end

  # Configuration

  defp config(key, default) do
    :ex_vat
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, Application.get_env(:ex_vat, key, default))
  end

  defp base_url do
    config(:base_url, @default_base_url)
  end

  defp http_client do
    Application.get_env(:ex_vat, :http_client, ExVat.HTTP)
  end

  defp http_options do
    [
      timeout: config(:timeout, @default_timeout),
      recv_timeout: config(:recv_timeout, @default_recv_timeout)
    ]
  end
end
