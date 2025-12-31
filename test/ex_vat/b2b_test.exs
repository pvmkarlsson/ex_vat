defmodule ExVat.B2BTest do
  use ExUnit.Case, async: true

  alias ExVat.B2B

  describe "standard_rate/1" do
    test "returns VAT rate for EU countries" do
      assert B2B.standard_rate("SE") == 25
      assert B2B.standard_rate("DE") == 19
      assert B2B.standard_rate("HU") == 27  # Highest in EU
      assert B2B.standard_rate("LU") == 17  # Lowest in EU
    end

    test "handles Greece (EL and GR)" do
      assert B2B.standard_rate("EL") == 24
      assert B2B.standard_rate("GR") == 24
    end

    test "returns nil for non-EU countries" do
      assert B2B.standard_rate("US") == nil
      assert B2B.standard_rate("XX") == nil
    end
  end

  describe "eu_member?/1" do
    test "returns true for EU countries" do
      assert B2B.eu_member?("SE") == true
      assert B2B.eu_member?("DE") == true
      assert B2B.eu_member?("XI") == true  # Northern Ireland
    end

    test "handles Greece (EL and GR)" do
      assert B2B.eu_member?("EL") == true
      assert B2B.eu_member?("GR") == true
    end

    test "returns false for non-EU countries" do
      assert B2B.eu_member?("US") == false
      assert B2B.eu_member?("XX") == false
    end
  end

  describe "same_country?/2" do
    test "returns true for same country" do
      assert B2B.same_country?("SE", "SE") == true
      assert B2B.same_country?("DE", "DE") == true
    end

    test "handles case insensitivity" do
      assert B2B.same_country?("se", "SE") == true
      assert B2B.same_country?("Se", "sE") == true
    end

    test "normalizes Greece codes" do
      assert B2B.same_country?("EL", "GR") == true
      assert B2B.same_country?("GR", "EL") == true
    end

    test "returns false for different countries" do
      assert B2B.same_country?("SE", "DE") == false
    end
  end

  describe "cross_border_eu?/2" do
    test "returns true for different EU countries" do
      assert B2B.cross_border_eu?("SE", "DE") == true
      assert B2B.cross_border_eu?("FR", "IT") == true
    end

    test "returns false for same country" do
      assert B2B.cross_border_eu?("SE", "SE") == false
      assert B2B.cross_border_eu?("EL", "GR") == false  # Same country (Greece)
    end

    test "returns false when one party is non-EU" do
      assert B2B.cross_border_eu?("SE", "US") == false
      assert B2B.cross_border_eu?("US", "DE") == false
    end
  end

  describe "tax_treatment/3" do
    test "returns :domestic for same country" do
      assert B2B.tax_treatment("SE", "SE") == :domestic
      assert B2B.tax_treatment("DE", "DE") == :domestic
    end

    test "returns :reverse_charge for cross-border EU B2B with valid VAT" do
      assert B2B.tax_treatment("SE", "DE", buyer_vat_valid: true, b2b: true) == :reverse_charge
    end

    test "returns :standard for cross-border EU B2C" do
      assert B2B.tax_treatment("SE", "DE", b2b: false) == :standard
    end

    test "returns :standard for cross-border EU B2B with invalid VAT" do
      assert B2B.tax_treatment("SE", "DE", buyer_vat_valid: false) == :standard
    end

    test "returns :export for EU seller to non-EU buyer" do
      assert B2B.tax_treatment("SE", "US") == :export
      assert B2B.tax_treatment("DE", "CA") == :export
    end

    test "returns :import for non-EU seller to EU buyer" do
      assert B2B.tax_treatment("US", "SE") == :import
      assert B2B.tax_treatment("CN", "DE") == :import
    end

    test "returns :outside_eu for non-EU to non-EU" do
      assert B2B.tax_treatment("US", "CA") == :outside_eu
    end
  end

  describe "applicable_rate/3" do
    test "returns seller's rate for domestic" do
      assert B2B.applicable_rate("SE", "SE") == 25
      assert B2B.applicable_rate("DE", "DE") == 19
    end

    test "returns 0 for reverse charge" do
      assert B2B.applicable_rate("SE", "DE", buyer_vat_valid: true) == 0
    end

    test "returns seller's rate for standard (B2C cross-border)" do
      assert B2B.applicable_rate("SE", "DE", b2b: false) == 25
    end

    test "returns 0 for export" do
      assert B2B.applicable_rate("SE", "US") == 0
    end

    test "returns buyer's rate for import" do
      assert B2B.applicable_rate("US", "SE") == 25
    end

    test "returns nil for outside EU" do
      assert B2B.applicable_rate("US", "CA") == nil
    end
  end

  describe "reverse_charge_applies?/3" do
    test "returns true for valid cross-border EU B2B" do
      assert B2B.reverse_charge_applies?("SE", "DE", true) == true
    end

    test "returns false for same country" do
      assert B2B.reverse_charge_applies?("SE", "SE", true) == false
    end

    test "returns false when buyer VAT not valid" do
      assert B2B.reverse_charge_applies?("SE", "DE", false) == false
    end

    test "returns false when seller not in EU" do
      assert B2B.reverse_charge_applies?("US", "DE", true) == false
    end

    test "returns false when buyer not in EU" do
      assert B2B.reverse_charge_applies?("SE", "US", true) == false
    end
  end

  describe "reverse_charge_text/1" do
    test "returns English text by default" do
      text = B2B.reverse_charge_text()
      assert String.contains?(text, "reverse charge")
      assert String.contains?(text, "Article 194")
    end

    test "returns short format" do
      text = B2B.reverse_charge_text(format: :short)
      assert text == "Reverse charge"
    end

    test "returns German text" do
      text = B2B.reverse_charge_text(language: "de")
      assert String.contains?(text, "Steuerschuldnerschaft")
    end

    test "returns Swedish text" do
      text = B2B.reverse_charge_text(language: "sv")
      assert String.contains?(text, "Omvänd skattskyldighet")
    end

    test "falls back to English for unknown language" do
      text = B2B.reverse_charge_text(language: "xx")
      assert String.contains?(text, "reverse charge")
    end
  end

  describe "invoice_text/2" do
    test "returns text for reverse charge" do
      text = B2B.invoice_text(:reverse_charge)
      assert String.contains?(text, "reverse charge")
    end

    test "returns text for export" do
      text = B2B.invoice_text(:export)
      assert String.contains?(text, "Zero-rated export")
    end

    test "returns nil for domestic" do
      assert B2B.invoice_text(:domestic) == nil
    end
  end

  describe "validate_transaction/5 with offline validation" do
    test "returns correct result for cross-border EU transaction" do
      {:ok, tx} = B2B.validate_transaction(
        "SE", "556012345601",
        "DE", "123456789",
        validate_online: false
      )

      assert tx.seller_valid == true
      assert tx.buyer_valid == true
      assert tx.same_country == false
      assert tx.cross_border_eu == true
      assert tx.reverse_charge == true
      assert tx.tax_treatment == :reverse_charge
      assert tx.vat_rate == 0
    end

    test "returns correct result for same country transaction" do
      {:ok, tx} = B2B.validate_transaction(
        "SE", "556012345601",
        "SE", "556789012301",
        validate_online: false
      )

      assert tx.same_country == true
      assert tx.cross_border_eu == false
      assert tx.reverse_charge == false
      assert tx.tax_treatment == :domestic
      assert tx.vat_rate == 25
    end

    test "returns error for bad VAT format" do
      result = B2B.validate_transaction(
        "SE", "556012345601",
        "DE", "123",  # Invalid length for DE
        validate_online: false
      )

      assert {:error, :invalid_length} = result
    end

    test "returns error for invalid country code" do
      result = B2B.validate_transaction(
        "XX", "123456789",
        "DE", "123456789",
        validate_online: false
      )

      assert {:error, :invalid_country_code} = result
    end
  end

  describe "reverse_charge?/5" do
    test "returns true for valid cross-border EU" do
      result = B2B.reverse_charge?(
        "SE", "556012345601",
        "DE", "123456789",
        validate_online: false
      )

      assert result == true
    end

    test "returns false for same country" do
      result = B2B.reverse_charge?(
        "SE", "556012345601",
        "SE", "556789012301",
        validate_online: false
      )

      assert result == false
    end
  end

  describe "both_valid?/5" do
    test "returns true when both VATs are valid format" do
      result = B2B.both_valid?(
        "SE", "556012345601",
        "DE", "123456789",
        validate_online: false
      )

      assert result == true
    end

    test "returns false when one VAT is invalid format" do
      result = B2B.both_valid?(
        "SE", "556012345601",
        "DE", "123",
        validate_online: false
      )

      assert result == false
    end
  end
end
