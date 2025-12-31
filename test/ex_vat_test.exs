defmodule ExVatTest do
  use ExUnit.Case

  import Mox

  alias ExVat.{Error, Result}

  setup :verify_on_exit!

  describe "validate/3" do
    test "validates using mock adapter" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "556012345601",
        "requestDate" => "2024-01-15T10:30:00Z",
        "name" => "TEST COMPANY"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, %Result{} = result} = ExVat.validate("SE", "556012345601")

      assert result.valid == true
      assert result.country_code == "SE"
      assert result.name == "TEST COMPANY"
    end

    test "normalizes input by default" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "556012345601"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, body, _headers, _opts ->
        decoded = JSON.decode!(body)
        # Should be normalized (spaces and dashes removed)
        assert decoded["vatNumber"] == "556012345601"
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, _} = ExVat.validate("se", "SE 556-012.345 601")
    end

    test "returns error for invalid country code" do
      result = ExVat.validate("XX", "123456789")

      assert result == {:error, :invalid_country_code}
    end

    test "strict mode validates format first" do
      # With strict mode, this should fail before making an API call
      result = ExVat.validate("SE", "123", strict: true)

      assert result == {:error, :invalid_length}
    end

    test "uses fallback adapter on retryable errors" do
      # Expect 4 calls due to retry logic (1 initial + 3 retries)
      ExVat.MockHTTPClient
      |> expect(:post, 4, fn _url, _body, _headers, _opts ->
        {:error, %{reason: :timeout}}
      end)

      # Configure fallback
      Application.put_env(:ex_vat, :fallback_adapter, ExVat.Adapter.Regex)

      on_exit(fn ->
        Application.delete_env(:ex_vat, :fallback_adapter)
      end)

      # Should fallback to regex adapter after retries exhausted
      assert {:ok, result} = ExVat.validate("SE", "556012345601", fallback: true)

      assert result.adapter == ExVat.Adapter.Regex
    end

    test "can override adapter" do
      # Using regex adapter directly
      {:ok, result} = ExVat.validate("SE", "556012345601", adapter: ExVat.Adapter.Regex)

      assert result.adapter == ExVat.Adapter.Regex
      assert result.valid == true
    end
  end

  describe "validate!/3" do
    test "returns result on success" do
      response_body = JSON.encode!(%{
        "valid" => true,
        "countryCode" => "SE",
        "vatNumber" => "556012345601"
      })

      ExVat.MockHTTPClient
      |> expect(:post, fn _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      result = ExVat.validate!("SE", "556012345601")

      assert result.valid == true
    end

    test "raises on invalid country code" do
      assert_raise Error, ~r/INVALID_COUNTRY/, fn ->
        ExVat.validate!("XX", "123456789")
      end
    end

    test "raises on invalid format in strict mode" do
      assert_raise Error, ~r/INVALID_LENGTH/, fn ->
        ExVat.validate!("SE", "123", strict: true)
      end
    end
  end

  describe "validate_format/2" do
    test "returns :ok for valid format" do
      assert ExVat.validate_format("SE", "556012345601") == :ok
      assert ExVat.validate_format("DE", "123456789") == :ok
    end

    test "returns error for invalid format" do
      assert ExVat.validate_format("SE", "123") == {:error, :invalid_length}
      assert ExVat.validate_format("XX", "123") == {:error, :invalid_country_code}
    end
  end

  describe "valid_format?/2" do
    test "returns boolean" do
      assert ExVat.valid_format?("SE", "556012345601") == true
      assert ExVat.valid_format?("SE", "123") == false
    end
  end

  describe "check_status/1" do
    test "returns status from adapter" do
      response_body = JSON.encode!(%{
        "vow" => %{"available" => true},
        "countries" => [
          %{"countryCode" => "SE", "availability" => "Available"}
        ]
      })

      ExVat.MockHTTPClient
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      {:ok, status} = ExVat.check_status()

      assert status.available == true
      assert length(status.countries) == 1
    end
  end

  describe "country_available?/2" do
    test "returns true for available country" do
      response_body = JSON.encode!(%{
        "vow" => %{"available" => true},
        "countries" => [
          %{"countryCode" => "SE", "availability" => "Available"}
        ]
      })

      ExVat.MockHTTPClient
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert ExVat.country_available?("SE") == true
    end

    test "returns false for unavailable country" do
      response_body = JSON.encode!(%{
        "vow" => %{"available" => true},
        "countries" => [
          %{"countryCode" => "SE", "availability" => "Unavailable"}
        ]
      })

      ExVat.MockHTTPClient
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert ExVat.country_available?("SE") == false
    end
  end

  describe "country_codes/0" do
    test "returns all EU country codes" do
      codes = ExVat.country_codes()

      assert is_list(codes)
      assert "SE" in codes
      assert "DE" in codes
      assert length(codes) == 28
    end
  end

  describe "country_name/1" do
    test "returns country name" do
      assert ExVat.country_name("SE") == "Sweden"
      assert ExVat.country_name("DE") == "Germany"
    end

    test "returns nil for invalid code" do
      assert ExVat.country_name("XX") == nil
    end
  end

  describe "countries/0" do
    test "returns map of country codes to names" do
      countries = ExVat.countries()

      assert is_map(countries)
      assert countries["SE"] == "Sweden"
      assert countries["DE"] == "Germany"
    end
  end

  describe "normalize/2" do
    test "normalizes input" do
      assert ExVat.normalize("se", "SE 556-012.345 601") == {:ok, "SE", "556012345601"}
    end

    test "returns error for invalid country" do
      assert ExVat.normalize("XX", "123") == {:error, :invalid_country_code}
    end
  end

  describe "extract_country_code/1" do
    test "extracts country code from prefixed VAT" do
      assert ExVat.extract_country_code("SE556012345601") == {:ok, "SE", "556012345601"}
    end
  end

  describe "valid_country_code?/1" do
    test "returns true for valid EU codes" do
      assert ExVat.valid_country_code?("SE") == true
      assert ExVat.valid_country_code?("DE") == true
    end

    test "returns false for invalid codes" do
      assert ExVat.valid_country_code?("US") == false
      assert ExVat.valid_country_code?("XX") == false
    end
  end
end
