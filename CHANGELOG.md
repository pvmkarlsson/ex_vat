# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-31

### Added

- `ExVat.HTTP` module - HTTP client wrapper with behaviour for custom implementations
- `ExVat.B2B` module - B2B cross-border VAT calculations and tax treatment logic
- `ExVat.B2B.Transaction` struct - Structured transaction data for B2B operations
- `ExVat.TEDB` module - EU TEDB (Taxes in Europe Database) SOAP API client
- `ExVat.TEDB.Rate` struct - VAT rate data with type, category, and validity info
- `ExVat.TEDB.Categories` module - Common TEDB category constants
- `ExVat.TARIC` module - EU TARIC (Integrated Tariff) SOAP API client
- `ExVat.TARIC.Goods` struct - CN code goods data with VAT rates
- Support for trader matching (name, street, city, postal code, company type)
- Request identifier support for audit trails
- VAT number correction detection and messaging

### Changed

- Replaced HTTPoison with Req for HTTP requests (smaller dependency tree, HTTP/2 support)
- Replaced Jason with built-in `JSON` module (requires Elixir 1.18+)
- Updated minimum Elixir version to 1.19
- Improved error handling with structured `ExVat.Error` type
- Refactored code for better Credo strict mode compliance

### Fixed

- Improved input normalization for VAT numbers with special characters
- Better handling of VIES API error responses

## [0.1.0] - 2024-12-01

### Added

- Initial release
- `ExVat` main module for VAT validation
- `ExVat.Adapter.Vies` - VIES REST API adapter
- `ExVat.Adapter.Regex` - Offline regex validation adapter
- `ExVat.Format` - VAT number format validation
- `ExVat.Result` struct - Validation result data
- `ExVat.Error` struct - Structured error handling
- Support for all 27 EU member states + Northern Ireland (XI)
- Automatic retry with exponential backoff
- Test mode support for VIES API
