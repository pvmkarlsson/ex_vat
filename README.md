# ExVat

A flexible EU VAT validation library for Elixir with pluggable adapters.

## Features

- **Multiple Adapters**: Switch between VIES API and offline regex validation
- **Automatic Retry**: Exponential backoff for transient failures
- **Input Normalization**: Automatically handles spaces, dashes, and country prefixes
- **B2B Utilities**: Cross-border VAT calculations and reverse charge detection
- **Format Validation**: Offline validation using country-specific patterns
- **Company Lookup**: Get registered name and address (VIES adapter)
- **Trader Matching**: Approximate matching for verification (VIES adapter)

## Installation

Add `ex_vat` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_vat, "~> 0.2.0"}
  ]
end
```

## Quick Start

```elixir
# Simple validation
{:ok, result} = ExVat.validate("SE", "556012345601")
result.valid    #=> true
result.name     #=> "COMPANY AB"
result.address  #=> "STREET 1, 123 45 CITY"

# Format validation only (no API call)
ExVat.valid_format?("SE", "556012345601")  #=> true

# Check if reverse charge applies
ExVat.B2B.reverse_charge?("SE", "556012345601", "DE", "123456789")  #=> true
```

## Configuration

```elixir
# config/config.exs
config :ex_vat,
  adapter: ExVat.Adapter.Vies,
  fallback_adapter: ExVat.Adapter.Regex

# VIES adapter settings
config :ex_vat, ExVat.Adapter.Vies,
  timeout: 30_000,
  recv_timeout: 15_000,
  max_retries: 3,
  retry_delay: 1_000,
  retry_backoff: :exponential  # :constant | :exponential | :jittered
```

## Adapters

### ExVat.Adapter.Vies (Default)

Full integration with the official EU VIES API:

```elixir
{:ok, result} = ExVat.validate("DE", "123456789")

# With request identifier (for audit trail)
{:ok, result} = ExVat.validate("DE", "123456789",
  requester_member_state_code: "SE",
  requester_number: "556012345601"
)
result.request_identifier  #=> "WAPIAAAAW..."

# With trader matching
{:ok, result} = ExVat.validate("FR", "12345678901",
  trader_name: "ACME Corporation",
  trader_city: "Paris"
)
result.trader_name_match  #=> :valid | :invalid | :not_processed
```

### ExVat.Adapter.Regex

Offline format validation (no API calls):

```elixir
# Use directly
{:ok, result} = ExVat.validate("SE", "556012345601", adapter: ExVat.Adapter.Regex)

# Or set as default
config :ex_vat, adapter: ExVat.Adapter.Regex
```

### Custom Adapters

Implement the `ExVat.Adapter` behaviour:

```elixir
defmodule MyApp.VatAdapter do
  @behaviour ExVat.Adapter

  @impl true
  def validate(country_code, vat_number, opts) do
    # Your validation logic
    {:ok, %ExVat.Result{valid: true, ...}}
  end

  @impl true
  def validate_format(country_code, vat_number) do
    ExVat.Format.validate(country_code, vat_number)
  end

  @impl true
  def check_status, do: {:ok, %{available: true, countries: []}}

  @impl true
  def supports_country?(code), do: ExVat.Format.valid_country_code?(code)

  @impl true
  def capabilities, do: [:validate, :validate_format, :check_status]
end
```

## B2B Cross-Border VAT

The `ExVat.B2B` module helps with cross-border B2B transactions:

```elixir
# Check transaction details
{:ok, tx} = ExVat.B2B.check_transaction("SE", "556012345601", "DE", "123456789")
tx.reverse_charge   #=> true
tx.vat_treatment    #=> :reverse_charge
tx.seller_valid     #=> true
tx.buyer_valid      #=> true
tx.cross_border_eu  #=> true

# Quick reverse charge check
ExVat.B2B.reverse_charge?("SE", "556012345601", "DE", "123456789")
#=> true

# Get invoice text for reverse charge
ExVat.B2B.reverse_charge_text()
#=> "VAT reverse charge applies according to Article 194..."

ExVat.B2B.reverse_charge_text(language: "de", format: :short)
#=> "Steuerschuldnerschaft des Leistungsempfängers"
```

### VAT Treatment Types

| Scenario | Treatment |
|----------|-----------|
| Same EU country | `:standard` |
| Cross-border EU, both valid | `:reverse_charge` |
| Cross-border EU, buyer invalid | `:standard` |
| Non-EU party | `:outside_scope` |

## Input Normalization

ExVat automatically normalizes input:

```elixir
# All of these work:
ExVat.validate("SE", "556012345601")
ExVat.validate("se", "SE 556-012.345 601")
ExVat.validate("SE", "SE556012345601")
```

Disable normalization:

```elixir
ExVat.validate("SE", "556012345601", normalize: false)
```

## Format Validation

Validate format before API calls:

```elixir
# Check format only (no API call)
ExVat.validate_format("SE", "556012345601")  #=> :ok
ExVat.validate_format("SE", "123")           #=> {:error, :invalid_length}

# Strict mode: validate format before calling API
ExVat.validate("SE", "123", strict: true)
#=> {:error, :invalid_length}  # No API call made
```

## Service Status

Check VIES service availability:

```elixir
{:ok, status} = ExVat.check_status()
status.available  #=> true

# Available countries
status.countries
#=> [%{country_code: "SE", available: true}, ...]

# Check specific country
ExVat.country_available?("SE")  #=> true
```

## Testing

### Using Test Endpoint

VIES provides a test endpoint for integration testing:

```elixir
# VAT number "100" returns VALID
{:ok, result} = ExVat.validate("SE", "100", test_mode: true)
result.valid  #=> true

# VAT number "200" returns INVALID
{:ok, result} = ExVat.validate("SE", "200", test_mode: true)
result.valid  #=> false
```

### Mocking for Unit Tests

```elixir
# test/test_helper.exs
Mox.defmock(ExVat.MockHTTPClient, for: HTTPoison.Base)
Application.put_env(:ex_vat, :http_client, ExVat.MockHTTPClient)

# In your tests
import Mox

test "validates VAT number" do
  ExVat.MockHTTPClient
  |> expect(:post, fn _url, _body, _headers, _opts ->
    {:ok, %{status_code: 200, body: Jason.encode!(%{"valid" => true, ...})}}
  end)

  assert {:ok, result} = ExVat.validate("SE", "556012345601")
  assert result.valid == true
end
```

### Integration Tests

```bash
# Run integration tests (hits real VIES API)
mix test --only integration
```

## Supported Countries

| Code | Country | Code | Country |
|------|---------|------|---------|
| AT | Austria | LT | Lithuania |
| BE | Belgium | LU | Luxembourg |
| BG | Bulgaria | LV | Latvia |
| CY | Cyprus | MT | Malta |
| CZ | Czech Republic | NL | Netherlands |
| DE | Germany | PL | Poland |
| DK | Denmark | PT | Portugal |
| EE | Estonia | RO | Romania |
| EL | Greece | SE | Sweden |
| ES | Spain | SI | Slovenia |
| FI | Finland | SK | Slovakia |
| FR | France | XI | Northern Ireland |
| HR | Croatia | | |
| HU | Hungary | | |
| IE | Ireland | | |
| IT | Italy | | |

## Error Handling

```elixir
case ExVat.validate("SE", "556012345601") do
  {:ok, result} ->
    if result.valid do
      IO.puts("Valid! Company: #{result.name}")
    else
      IO.puts("Invalid VAT number")
    end

  {:error, %ExVat.Error{} = error} ->
    IO.puts("Error: #{error.message}")

    if ExVat.Error.retryable?(error) do
      # Retry later
    end
end

# Or use bang functions
try do
  result = ExVat.validate!("SE", "556012345601")
rescue
  e in ExVat.Error ->
    IO.puts("Error: #{e.message}")
end
```

## VIES API Reference

This library uses the EU VIES REST API. For more information:

- [VIES Technical Information](https://ec.europa.eu/taxation_customs/vies/)
- [API Documentation](https://ec.europa.eu/assets/taxud/vow-information/swagger_publicVAT.yaml)

## License

MIT
