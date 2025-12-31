defmodule ExVat.Adapter do
  @moduledoc """
  Behaviour for VAT validation adapters.

  This module defines the contract that all VAT validation adapters must implement.
  Adapters can range from simple regex-based format validators to full API integrations.

  ## Implementing an Adapter

  To create a custom adapter, implement all callbacks defined by this behaviour:

      defmodule MyApp.VatAdapter.CustomApi do
        @behaviour ExVat.Adapter

        @impl true
        def validate(country_code, vat_number, opts) do
          # Your validation logic here
          {:ok, %ExVat.Result{valid: true, ...}}
        end

        @impl true
        def validate_format(country_code, vat_number) do
          # Format-only validation
          :ok
        end

        @impl true
        def check_status do
          # Return service availability
          {:ok, %{available: true, countries: [...]}}
        end

        @impl true
        def supports_country?(country_code) do
          country_code in ["DE", "FR", ...]
        end

        @impl true
        def capabilities do
          [:validate, :validate_format, :check_status, :trader_matching]
        end
      end

  ## Built-in Adapters

    * `ExVat.Adapter.Vies` - Full EU VIES API integration with retry logic
    * `ExVat.Adapter.Regex` - Offline format validation only (no API calls)

  ## Configuration

      config :ex_vat,
        adapter: ExVat.Adapter.Vies,
        fallback_adapter: ExVat.Adapter.Regex  # Used when primary fails
  """

  alias ExVat.Result

  @type country_code :: String.t()
  @type vat_number :: String.t()
  @type capability ::
          :validate
          | :validate_format
          | :check_status
          | :trader_matching
          | :request_identifier
          | :batch_validation

  @type validate_opts :: [
          requester_member_state_code: String.t(),
          requester_number: String.t(),
          trader_name: String.t(),
          trader_street: String.t(),
          trader_postal_code: String.t(),
          trader_city: String.t(),
          trader_company_type: String.t(),
          timeout: non_neg_integer()
        ]

  @type status_result :: %{
          available: boolean(),
          countries: [%{country_code: String.t(), available: boolean()}]
        }

  @doc """
  Validates a VAT number against the adapter's data source.

  This is the main validation function. Depending on the adapter, this might:
    * Make an API call to a VAT validation service (e.g., VIES)
    * Perform local regex/checksum validation
    * Query a local database

  ## Parameters

    * `country_code` - Two-letter country code (e.g., "SE", "DE")
    * `vat_number` - The VAT number to validate
    * `opts` - Adapter-specific options

  ## Returns

    * `{:ok, %ExVat.Result{}}` - Validation result
    * `{:error, reason}` - Validation failed
  """
  @callback validate(country_code(), vat_number(), validate_opts()) ::
              {:ok, Result.t()} | {:error, term()}

  @doc """
  Validates only the format of a VAT number without making external calls.

  This should be a fast, local-only check of the VAT number format.

  ## Returns

    * `:ok` - Format is valid
    * `{:error, reason}` - Format is invalid
  """
  @callback validate_format(country_code(), vat_number()) ::
              :ok | {:error, :invalid_country_code | :invalid_format | :invalid_length}

  @doc """
  Checks the availability status of the validation service.

  For API-based adapters, this checks if the service is online.
  For local adapters, this typically returns `{:ok, %{available: true}}`.

  ## Returns

    * `{:ok, status_result()}` - Service status
    * `{:error, reason}` - Could not determine status
  """
  @callback check_status() :: {:ok, status_result()} | {:error, term()}

  @doc """
  Returns whether this adapter supports a given country code.
  """
  @callback supports_country?(country_code()) :: boolean()

  @doc """
  Returns a list of capabilities this adapter supports.

  Possible capabilities:
    * `:validate` - Can validate VAT numbers
    * `:validate_format` - Can validate format locally
    * `:check_status` - Can check service availability
    * `:trader_matching` - Supports approximate trader matching
    * `:request_identifier` - Can generate request identifiers
    * `:batch_validation` - Supports batch validation
  """
  @callback capabilities() :: [capability()]

  @doc """
  Optional callback for adapters that need initialization or cleanup.
  Called when the adapter is first used.
  """
  @callback init(keyword()) :: :ok | {:error, term()}

  @optional_callbacks [init: 1]

  # Helper functions for working with adapters

  @doc """
  Returns the configured primary adapter.
  """
  @spec adapter() :: module()
  def adapter do
    Application.get_env(:ex_vat, :adapter, ExVat.Adapter.Vies)
  end

  @doc """
  Returns the configured fallback adapter (used when primary fails).
  """
  @spec fallback_adapter() :: module() | nil
  def fallback_adapter do
    Application.get_env(:ex_vat, :fallback_adapter)
  end

  @doc """
  Checks if an adapter has a specific capability.
  """
  @spec has_capability?(module(), capability()) :: boolean()
  def has_capability?(adapter_module, capability) do
    capability in adapter_module.capabilities()
  end
end
