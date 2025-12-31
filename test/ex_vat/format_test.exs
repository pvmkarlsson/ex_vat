defmodule ExVat.FormatTest do
  use ExUnit.Case, async: true

  alias ExVat.Format

  describe "country_codes/0" do
    test "returns all EU country codes" do
      codes = Format.country_codes()

      assert is_list(codes)
      assert length(codes) == 28
      assert "SE" in codes
      assert "DE" in codes
      assert "FR" in codes
      assert "XI" in codes
    end
  end

  describe "country_name/1" do
    test "returns country name for valid codes" do
      assert Format.country_name("SE") == "Sweden"
      assert Format.country_name("DE") == "Germany"
      assert Format.country_name("FR") == "France"
      assert Format.country_name("EL") == "Greece"
      assert Format.country_name("XI") == "Northern Ireland"
    end

    test "handles lowercase codes" do
      assert Format.country_name("se") == "Sweden"
    end

    test "returns nil for invalid codes" do
      assert Format.country_name("XX") == nil
      assert Format.country_name("US") == nil
    end
  end

  describe "validate_country_code/1" do
    test "returns :ok for valid EU codes" do
      assert Format.validate_country_code("SE") == :ok
      assert Format.validate_country_code("DE") == :ok
      assert Format.validate_country_code("XI") == :ok
    end

    test "handles lowercase" do
      assert Format.validate_country_code("se") == :ok
    end

    test "returns error for invalid codes" do
      assert Format.validate_country_code("XX") == {:error, :invalid_country_code}
      assert Format.validate_country_code("US") == {:error, :invalid_country_code}
      assert Format.validate_country_code("") == {:error, :invalid_country_code}
    end

    test "returns error for non-binary input" do
      assert Format.validate_country_code(nil) == {:error, :invalid_country_code}
      assert Format.validate_country_code(123) == {:error, :invalid_country_code}
    end
  end

  describe "normalize_vat_number/2" do
    test "removes spaces, dashes and dots" do
      assert Format.normalize_vat_number("SE", "556 012-345.601") == "556012345601"
    end

    test "strips country prefix" do
      assert Format.normalize_vat_number("SE", "SE556012345601") == "556012345601"
      assert Format.normalize_vat_number("DE", "DE123456789") == "123456789"
    end

    test "handles mixed formatting" do
      assert Format.normalize_vat_number("SE", "SE 556-012.345 601") == "556012345601"
    end

    test "uppercases the result" do
      assert Format.normalize_vat_number("AT", "u12345678") == "U12345678"
    end

    test "handles Greece GR prefix" do
      # EL is official code but GR is commonly used
      assert Format.normalize_vat_number("EL", "GR123456789") == "123456789"
    end
  end

  describe "normalize/2" do
    test "normalizes country and vat number" do
      assert Format.normalize("se", "SE 556-012.345 601") == {:ok, "SE", "556012345601"}
    end

    test "returns error for invalid country" do
      assert Format.normalize("XX", "123456") == {:error, :invalid_country_code}
    end

    test "returns error for empty vat number" do
      assert Format.normalize("SE", "   ") == {:error, :empty_vat_number}
    end
  end

  describe "validate/2" do
    test "validates Swedish VAT numbers" do
      assert Format.validate("SE", "556012345601") == :ok
      assert Format.validate("SE", "123456789012") == :ok
    end

    test "rejects invalid Swedish VAT numbers" do
      assert Format.validate("SE", "123") == {:error, :invalid_length}
      assert Format.validate("SE", "5560123456") == {:error, :invalid_length}
    end

    test "validates German VAT numbers" do
      assert Format.validate("DE", "123456789") == :ok
    end

    test "rejects invalid German VAT numbers" do
      assert Format.validate("DE", "12345678") == {:error, :invalid_length}
      assert Format.validate("DE", "1234567890") == {:error, :invalid_length}
    end

    test "validates Austrian VAT numbers (U prefix)" do
      assert Format.validate("AT", "U12345678") == :ok
    end

    test "rejects Austrian VAT without U prefix" do
      # AT VAT format: U + 8 digits (total 9 chars)
      # "12345678" is only 8 chars, so it fails length check first
      assert Format.validate("AT", "12345678") == {:error, :invalid_length}
      # With correct length but wrong format:
      assert Format.validate("AT", "123456789") == {:error, :invalid_format}
    end

    test "validates Dutch VAT numbers (with B)" do
      assert Format.validate("NL", "123456789B01") == :ok
    end

    test "validates French VAT numbers (alphanumeric prefix)" do
      assert Format.validate("FR", "AB123456789") == :ok
      assert Format.validate("FR", "12345678901") == :ok
    end

    test "validates Spanish VAT numbers" do
      assert Format.validate("ES", "A12345678") == :ok
      assert Format.validate("ES", "12345678A") == :ok
    end

    test "validates Belgian VAT numbers" do
      assert Format.validate("BE", "0123456789") == :ok
      assert Format.validate("BE", "1234567890") == :ok
    end

    test "returns error for invalid country" do
      assert Format.validate("XX", "123456789") == {:error, :invalid_country_code}
    end
  end

  describe "validate_and_normalize/2" do
    test "normalizes and validates" do
      assert Format.validate_and_normalize("se", "SE 556-012-345.601") ==
        {:ok, "SE", "556012345601"}
    end

    test "returns error for invalid format after normalization" do
      assert Format.validate_and_normalize("SE", "123") == {:error, :invalid_length}
    end
  end

  describe "valid_format?/2" do
    test "returns true for valid formats" do
      assert Format.valid_format?("SE", "556012345601") == true
      assert Format.valid_format?("DE", "123456789") == true
    end

    test "returns false for invalid formats" do
      assert Format.valid_format?("SE", "123") == false
      assert Format.valid_format?("XX", "123") == false
    end
  end

  describe "extract_country_code/1" do
    test "extracts country code from prefixed VAT number" do
      assert Format.extract_country_code("SE556012345601") == {:ok, "SE", "556012345601"}
      assert Format.extract_country_code("DE123456789") == {:ok, "DE", "123456789"}
    end

    test "handles formatting in the VAT number" do
      assert Format.extract_country_code("SE 556-012.345 601") == {:ok, "SE", "556012345601"}
    end

    test "returns error for invalid country prefix" do
      assert Format.extract_country_code("XX123456789") == {:error, :invalid_country_code}
      assert Format.extract_country_code("US123456789") == {:error, :invalid_country_code}
    end

    test "returns error for numbers without prefix" do
      assert Format.extract_country_code("12") == {:error, :no_country_prefix}
      assert Format.extract_country_code("") == {:error, :no_country_prefix}
    end
  end

  describe "format_info/1" do
    test "returns format info for valid countries" do
      {min, max, pattern} = Format.format_info("SE")
      assert min == 12
      assert max == 12
      assert is_struct(pattern, Regex)
    end

    test "returns nil for invalid countries" do
      assert Format.format_info("XX") == nil
    end
  end
end
