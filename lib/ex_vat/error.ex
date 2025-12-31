defmodule ExVat.Error do
  @moduledoc """
  Exception module for VAT validation errors.

  This exception is raised by bang functions (e.g., `ExVat.validate!/3`) when
  an error occurs during VAT validation.

  ## Error Types

    * `:validation_error` - Input validation failed (invalid format, country code)
    * `:api_error` - The API returned an error response
    * `:http_error` - HTTP transport error (timeout, connection refused)
    * `:adapter_error` - Adapter-specific error
    * `:unknown` - Unknown error

  ## Examples

      try do
        ExVat.validate!("XX", "invalid")
      rescue
        e in ExVat.Error ->
          IO.puts("Error type: \#{e.type}")
          IO.puts("Message: \#{e.message}")
      end
  """

  @type error_type :: :validation_error | :api_error | :http_error | :adapter_error | :unknown

  @type t :: %__MODULE__{
          type: error_type(),
          code: String.t() | nil,
          message: String.t(),
          adapter: module() | nil,
          details: term()
        }

  defexception [:type, :code, :message, :adapter, :details]

  @impl true
  def message(%__MODULE__{} = error) do
    base = error.message || "Unknown VAT validation error"

    case error.code do
      nil -> base
      code -> "[#{code}] #{base}"
    end
  end

  @doc """
  Creates a validation error for invalid country code.
  """
  @spec invalid_country_code(String.t()) :: t()
  def invalid_country_code(country_code) do
    %__MODULE__{
      type: :validation_error,
      code: "INVALID_COUNTRY",
      message: "Invalid or unsupported country code: #{country_code}",
      details: {:invalid_country_code, country_code}
    }
  end

  @doc """
  Creates a validation error for invalid VAT format.
  """
  @spec invalid_format(String.t(), String.t()) :: t()
  def invalid_format(country_code, vat_number) do
    %__MODULE__{
      type: :validation_error,
      code: "INVALID_FORMAT",
      message: "Invalid VAT number format for country #{country_code}: #{vat_number}",
      details: {:invalid_format, country_code, vat_number}
    }
  end

  @doc """
  Creates a validation error for invalid VAT length.
  """
  @spec invalid_length(String.t(), String.t()) :: t()
  def invalid_length(country_code, vat_number) do
    %__MODULE__{
      type: :validation_error,
      code: "INVALID_LENGTH",
      message: "Invalid VAT number length for country #{country_code}",
      details: {:invalid_length, country_code, vat_number}
    }
  end

  @doc """
  Creates an API error from VIES error response.
  """
  @spec from_api_response(String.t() | nil, String.t() | nil, module()) :: t()
  def from_api_response(code, message, adapter) do
    %__MODULE__{
      type: :api_error,
      code: code,
      message: message || error_code_message(code) || "API error",
      adapter: adapter,
      details: %{code: code, message: message}
    }
  end

  @doc """
  Creates an HTTP error.
  """
  @spec from_http_error(term(), module()) :: t()
  def from_http_error(:timeout, adapter) do
    %__MODULE__{
      type: :http_error,
      code: "TIMEOUT",
      message: "Request to VAT validation service timed out",
      adapter: adapter,
      details: :timeout
    }
  end

  def from_http_error(:econnrefused, adapter) do
    %__MODULE__{
      type: :http_error,
      code: "CONNECTION_REFUSED",
      message: "Connection to VAT validation service refused",
      adapter: adapter,
      details: :econnrefused
    }
  end

  def from_http_error({:unexpected_status, status}, adapter) do
    %__MODULE__{
      type: :http_error,
      code: "HTTP_#{status}",
      message: "Unexpected HTTP status code: #{status}",
      adapter: adapter,
      details: {:unexpected_status, status}
    }
  end

  def from_http_error(reason, adapter) do
    %__MODULE__{
      type: :http_error,
      code: nil,
      message: "HTTP error: #{inspect(reason)}",
      adapter: adapter,
      details: reason
    }
  end

  @doc """
  Creates an adapter-specific error.
  """
  @spec adapter_error(String.t(), module(), term()) :: t()
  def adapter_error(message, adapter, details \\ nil) do
    %__MODULE__{
      type: :adapter_error,
      code: nil,
      message: message,
      adapter: adapter,
      details: details
    }
  end

  @doc """
  Returns true if this is a retryable error.
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{type: :http_error, code: "TIMEOUT"}), do: true
  def retryable?(%__MODULE__{type: :http_error, code: "CONNECTION_REFUSED"}), do: true
  def retryable?(%__MODULE__{code: "GLOBAL_MAX_CONCURRENT_REQ"}), do: true
  def retryable?(%__MODULE__{code: "GLOBAL_MAX_CONCURRENT_REQ_TIME"}), do: true
  def retryable?(%__MODULE__{code: "MS_MAX_CONCURRENT_REQ"}), do: true
  def retryable?(%__MODULE__{code: "SERVICE_UNAVAILABLE"}), do: true
  def retryable?(%__MODULE__{code: "SERVER_BUSY"}), do: true
  def retryable?(%__MODULE__{}), do: false

  # Known API error codes with human-readable messages
  defp error_code_message("INVALID_INPUT"), do: "Invalid input provided"
  defp error_code_message("GLOBAL_MAX_CONCURRENT_REQ"), do: "Maximum concurrent requests exceeded"

  defp error_code_message("GLOBAL_MAX_CONCURRENT_REQ_TIME"),
    do: "Maximum concurrent requests time exceeded"

  defp error_code_message("MS_MAX_CONCURRENT_REQ"), do: "Member state max concurrent requests exceeded"
  defp error_code_message("SERVICE_UNAVAILABLE"), do: "VAT validation service is unavailable"
  defp error_code_message("MS_UNAVAILABLE"), do: "Member state service is unavailable"
  defp error_code_message("TIMEOUT"), do: "Request timed out"
  defp error_code_message("VAT_BLOCKED"), do: "VAT number is blocked"
  defp error_code_message("IP_BLOCKED"), do: "IP address is blocked"
  defp error_code_message("SERVER_BUSY"), do: "Server is busy, try again later"
  defp error_code_message(_), do: nil
end
