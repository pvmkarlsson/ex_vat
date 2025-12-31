defmodule ExVat.Adapter.ViesTest do
  use ExUnit.Case

  import Mox

  alias ExVat.Adapter.Vies
  alias ExVat.{Error, Result}

  # Allow async tests to work with Mox
  setup :verify_on_exit!

  describe "validate/3" do
    test "returns valid result for valid VAT number" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "556012345601",
        "requestDate" => "2024-01-15T10:30:00Z",
        "name" => "TEST COMPANY AB",
        "address" => "TEST STREET 1\n123 45 STOCKHOLM"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, %Result{} = result} = Vies.validate("SE", "556012345601")

      assert result.valid == true
      assert result.country_code == "SE"
      assert result.vat_number == "556012345601"
      assert result.name == "TEST COMPANY AB"
      assert result.address == "TEST STREET 1\n123 45 STOCKHOLM"
      assert result.adapter == Vies
      assert result.country_name == "Sweden"
    end

    test "returns invalid result for invalid VAT number" do
      response_body = JSON.encode!(%{
        "valid" => false,
        "countryCode" => "SE",
        "vatNumber" => "000000000000",
        "requestDate" => "2024-01-15T10:30:00Z"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, %Result{} = result} = Vies.validate("SE", "000000000000")

      assert result.valid == false
    end

    test "handles request identifier" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "DE",
        "vatNumber" => "123456789",
        "requestDate" => "2024-01-15T10:30:00Z",
        "requestIdentifier" => "WAPIAAAAW123456"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, body, _headers, _opts ->
        decoded = JSON.decode!(body)
        assert decoded["requesterMemberStateCode"] == "SE"
        assert decoded["requesterNumber"] == "556012345601"
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, result} = Vies.validate("DE", "123456789",
        requester_member_state_code: "SE",
        requester_number: "556012345601"
      )

      assert result.request_identifier == "WAPIAAAAW123456"
    end

    test "handles trader matching" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "FR",
        "vatNumber" => "12345678901",
        "requestDate" => "2024-01-15T10:30:00Z",
        "traderName" => "ACME CORP",
        "traderNameMatch" => "VALID",
        "traderCity" => "PARIS",
        "traderCityMatch" => "VALID"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, body, _headers, _opts ->
        decoded = JSON.decode!(body)
        assert decoded["traderName"] == "ACME Corporation"
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, result} = Vies.validate("FR", "12345678901",
        trader_name: "ACME Corporation",
        trader_city: "Paris"
      )

      assert result.trader_name_match == :valid
      assert result.trader_city_match == :valid
    end

    test "handles VAT number correction" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "556012345601",
        "vatNumberCorrected" => true,
        "userError" => "Removed leading zeros",
        "requestDate" => "2024-01-15T10:30:00Z"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, result} = Vies.validate("SE", "0556012345601")

      assert result.corrected == true
      assert result.correction_message == "Removed leading zeros"
    end

    test "handles 400 error response" do
      response_body = JSON.encode!(%{
        "errorWrappers" => [%{
          "error" => "INVALID_INPUT",
          "message" => "Invalid VAT number format"
        }]
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 400, body: response_body}}
      end)

      assert {:error, %Error{} = error} = Vies.validate("SE", "invalid")

      assert error.type == :api_error
      assert error.code == "INVALID_INPUT"
    end

    test "handles 500 error response" do
      response_body = JSON.encode!(%{
        "errorWrappers" => [%{
          "error" => "SERVICE_UNAVAILABLE",
          "message" => "Service temporarily unavailable"
        }]
      })

      # With default retries, it will try multiple times
      ExVat.MockHTTPClient
      |> expect(:post, 4, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 500, body: response_body}}
      end)

      assert {:error, %Error{}} = Vies.validate("SE", "556012345601")
    end

    test "handles timeout" do
      ExVat.MockHTTPClient
      |> expect(:post, 4, fn _url, _body, _headers, _opts ->
        {:error, %{reason: :timeout}}
      end)

      assert {:error, %Error{} = error} = Vies.validate("SE", "556012345601")

      assert error.type == :http_error
      assert error.code == "TIMEOUT"
    end

    test "uses test endpoint in test mode" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "100"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn url, _body, _headers, _opts ->
        assert String.contains?(url, "check-vat-test-service")
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, result} = Vies.validate("SE", "100", test_mode: true)
      assert result.valid == true
    end
  end

  describe "check_status/0" do
    test "returns status for all member states" do
      response_body = JSON.encode!(%{
        "vow" => %{"available" => true},
        "countries" => [
          %{"countryCode" => "SE", "availability" => "Available"},
          %{"countryCode" => "DE", "availability" => "Available"},
          %{"countryCode" => "FR", "availability" => "Unavailable"}
        ]
      })

      ExVat.MockHTTPClient
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, status} = Vies.check_status()

      assert status.available == true
      assert length(status.countries) == 3

      se = Enum.find(status.countries, &(&1.country_code == "SE"))
      assert se.available == true

      fr = Enum.find(status.countries, &(&1.country_code == "FR"))
      assert fr.available == false
    end
  end

  describe "supports_country?/1" do
    test "returns true for EU countries" do
      assert Vies.supports_country?("SE") == true
      assert Vies.supports_country?("DE") == true
      assert Vies.supports_country?("XI") == true
    end

    test "returns false for non-EU countries" do
      assert Vies.supports_country?("US") == false
      assert Vies.supports_country?("XX") == false
    end
  end

  describe "capabilities/0" do
    test "returns full capabilities" do
      caps = Vies.capabilities()

      assert :validate in caps
      assert :validate_format in caps
      assert :check_status in caps
      assert :trader_matching in caps
      assert :request_identifier in caps
    end
  end
end
