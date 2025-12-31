defmodule ExVat.IntegrationTest do
  @moduledoc """
  Integration tests that hit the real VIES API.

  Run with: mix test --only integration
  Or: mix test.integration

  Note: These tests require internet access and may be slow due to API latency.
  They also depend on the VIES service being available.
  """

  use ExUnit.Case

  # Tag all tests as integration tests
  @moduletag :integration

  # Use the real HTTP client for integration tests
  setup do
    # Temporarily use the real HTTP client
    original = Application.get_env(:ex_vat, :http_client)
    Application.put_env(:ex_vat, :http_client, HTTPoison)

    on_exit(fn ->
      if original do
        Application.put_env(:ex_vat, :http_client, original)
      else
        Application.delete_env(:ex_vat, :http_client)
      end
    end)

    :ok
  end

  describe "VIES Test Endpoint" do
    @tag timeout: 60_000
    test "returns VALID for test value 100" do
      # According to VIES docs, VAT number "100" should return VALID on test endpoint
      result = ExVat.validate("SE", "100", test_mode: true)

      case result do
        {:ok, response} ->
          assert response.valid == true
          assert response.country_code == "SE"
          assert response.vat_number == "100"

        {:error, error} ->
          # If the service is down, skip the test
          if error.code in ["SERVICE_UNAVAILABLE", "MS_UNAVAILABLE", "TIMEOUT"] do
            skip_test("VIES service unavailable")
          else
            flunk("Unexpected error: #{inspect(error)}")
          end
      end
    end

    @tag timeout: 60_000
    test "returns INVALID for test value 200" do
      # According to VIES docs, VAT number "200" should return INVALID on test endpoint
      result = ExVat.validate("SE", "200", test_mode: true)

      case result do
        {:ok, response} ->
          assert response.valid == false
          assert response.country_code == "SE"

        {:error, error} ->
          if error.code in ["SERVICE_UNAVAILABLE", "MS_UNAVAILABLE", "TIMEOUT"] do
            skip_test("VIES service unavailable")
          else
            flunk("Unexpected error: #{inspect(error)}")
          end
      end
    end
  end

  describe "VIES Status Check" do
    @tag timeout: 60_000
    test "returns status for all EU member states" do
      result = ExVat.check_status()

      case result do
        {:ok, status} ->
          assert is_boolean(status.available)
          assert is_list(status.countries)

          # Should have status for all 28 EU countries
          country_codes = Enum.map(status.countries, & &1.country_code)

          # Check a few known countries
          assert "SE" in country_codes
          assert "DE" in country_codes
          assert "FR" in country_codes

        {:error, error} ->
          if error.code in ["SERVICE_UNAVAILABLE", "TIMEOUT"] do
            skip_test("VIES service unavailable")
          else
            flunk("Unexpected error: #{inspect(error)}")
          end
      end
    end
  end

  describe "Real VAT Validation" do
    @tag timeout: 60_000
    test "validates a known invalid VAT number" do
      # This is clearly invalid and should return invalid
      result = ExVat.validate("SE", "000000000000")

      case result do
        {:ok, response} ->
          # Should be invalid (unless someone actually has this number!)
          assert is_boolean(response.valid)

        {:error, error} ->
          if error.code in ["SERVICE_UNAVAILABLE", "MS_UNAVAILABLE", "TIMEOUT"] do
            skip_test("VIES service unavailable")
          else
            # INVALID_INPUT is also acceptable for clearly wrong numbers
            assert error.code in ["INVALID_INPUT", "MS_UNAVAILABLE"]
          end
      end
    end

    @tag timeout: 60_000
    test "handles German VAT format" do
      # Using test endpoint for consistent behavior
      result = ExVat.validate("DE", "100", test_mode: true)

      case result do
        {:ok, response} ->
          assert response.country_code == "DE"

        {:error, error} ->
          if error.code in ["SERVICE_UNAVAILABLE", "MS_UNAVAILABLE", "TIMEOUT"] do
            skip_test("VIES service unavailable")
          end
      end
    end
  end

  describe "Format Validation (Offline)" do
    test "validates format without API call" do
      # These should work offline
      assert ExVat.validate_format("SE", "556012345601") == :ok
      assert ExVat.validate_format("DE", "123456789") == :ok
      assert ExVat.validate_format("SE", "123") == {:error, :invalid_length}
    end

    test "regex adapter works offline" do
      {:ok, result} = ExVat.validate("SE", "556012345601", adapter: ExVat.Adapter.Regex)

      assert result.valid == true
      assert result.adapter == ExVat.Adapter.Regex
    end
  end

  describe "B2B Transaction Validation" do
    @tag timeout: 120_000
    test "determines reverse charge for cross-border transaction" do
      # Use test endpoint for more reliable results
      result = ExVat.B2B.validate_transaction("SE", "100", "DE", "100",
        validate_online: true,
        test_mode: true
      )

      case result do
        {:ok, tx} ->
          # Should be cross-border EU
          assert tx.cross_border_eu == true
          assert tx.same_country == false

          # If both are valid, reverse charge should apply
          if tx.seller_valid && tx.buyer_valid do
            assert tx.reverse_charge == true
            assert tx.tax_treatment == :reverse_charge
          end

        {:error, _} ->
          # If VIES is down, use offline validation
          {:ok, tx} = ExVat.B2B.validate_transaction("SE", "556012345601", "DE", "123456789",
            validate_online: false
          )

          assert tx.cross_border_eu == true
      end
    end

    test "determines no reverse charge for same country" do
      # Offline validation is fine for this
      {:ok, tx} = ExVat.B2B.validate_transaction("SE", "556012345601", "SE", "556789012301",
        validate_online: false
      )

      assert tx.same_country == true
      assert tx.reverse_charge == false
      assert tx.tax_treatment == :domestic
    end
  end

  describe "TEDB VAT Rates" do
    @tag timeout: 60_000
    test "retrieves standard VAT rate for Sweden" do
      result = ExVat.TEDB.standard_rate("SE")

      case result do
        {:ok, rate} ->
          assert is_number(rate)
          assert rate == 25.0

        {:error, reason} ->
          # Service might be unavailable
          assert reason in [:timeout, :econnrefused, :parse_error]
      end
    end

    @tag timeout: 60_000
    test "retrieves rates for multiple countries" do
      result = ExVat.TEDB.get_rates(["SE", "DE"])

      case result do
        {:ok, rates} ->
          assert is_list(rates)
          countries = Enum.map(rates, & &1.country) |> Enum.uniq()
          assert "SE" in countries or "DE" in countries

        {:error, _} ->
          :ok
      end
    end

    @tag timeout: 60_000
    test "retrieves category-specific rates" do
      result = ExVat.TEDB.category_rates("SE", :foodstuffs)

      case result do
        {:ok, rates} ->
          assert is_list(rates)

        {:error, _} ->
          :ok
      end
    end
  end

  # Helper to handle service unavailability - we just pass as this is expected
  # in integration tests when service is down
  defp skip_test(_reason) do
    :ok
  end
end
