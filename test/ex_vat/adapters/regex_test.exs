defmodule ExVat.Adapter.RegexTest do
  use ExUnit.Case, async: true

  alias ExVat.Adapter.Regex
  alias ExVat.Result

  describe "validate/3" do
    test "returns valid result for valid VAT format" do
      assert {:ok, %Result{} = result} = Regex.validate("SE", "556012345601")

      assert result.valid == true
      assert result.country_code == "SE"
      assert result.vat_number == "556012345601"
      assert result.adapter == Regex
      assert result.country_name == "Sweden"
    end

    test "normalizes input before validation" do
      assert {:ok, %Result{} = result} = Regex.validate("se", "SE 556-012.345 601")

      assert result.valid == true
      assert result.country_code == "SE"
      assert result.vat_number == "556012345601"
    end

    test "returns invalid result for invalid format" do
      assert {:ok, %Result{} = result} = Regex.validate("SE", "123")

      assert result.valid == false
      assert result.country_code == "SE"
      assert result.vat_number == "123"
    end

    test "returns invalid result for invalid country" do
      assert {:ok, %Result{} = result} = Regex.validate("XX", "123456789")

      assert result.valid == false
    end
  end

  describe "validate_format/2" do
    test "returns :ok for valid format" do
      assert Regex.validate_format("SE", "556012345601") == :ok
    end

    test "returns error for invalid format" do
      assert Regex.validate_format("SE", "123") == {:error, :invalid_length}
    end
  end

  describe "check_status/0" do
    test "always returns available" do
      {:ok, status} = Regex.check_status()

      assert status.available == true
      assert is_list(status.countries)
      assert length(status.countries) == 28

      # All countries should be available
      Enum.each(status.countries, fn c ->
        assert c.available == true
      end)
    end
  end

  describe "supports_country?/1" do
    test "returns true for EU countries" do
      assert Regex.supports_country?("SE") == true
      assert Regex.supports_country?("DE") == true
      assert Regex.supports_country?("se") == true
    end

    test "returns false for non-EU countries" do
      assert Regex.supports_country?("US") == false
      assert Regex.supports_country?("XX") == false
    end
  end

  describe "capabilities/0" do
    test "returns expected capabilities" do
      caps = Regex.capabilities()

      assert :validate in caps
      assert :validate_format in caps
      assert :check_status in caps

      # Should NOT have API-only capabilities
      refute :trader_matching in caps
      refute :request_identifier in caps
    end
  end
end
