defmodule ExVat.B2B.TransactionTest do
  use ExUnit.Case, async: true

  alias ExVat.B2B.Transaction

  describe "struct fields" do
    test "can create a transaction struct" do
      tx = %Transaction{
        seller_country: "SE",
        buyer_country: "DE",
        seller_vat: "556012345601",
        buyer_vat: "123456789",
        seller_valid: true,
        buyer_valid: true,
        same_country: false,
        cross_border_eu: true,
        reverse_charge: true,
        tax_treatment: :reverse_charge,
        vat_rate: 0,
        invoice_note: "VAT reverse charge applies..."
      }

      assert tx.seller_country == "SE"
      assert tx.buyer_country == "DE"
      assert tx.seller_valid == true
      assert tx.buyer_valid == true
      assert tx.same_country == false
      assert tx.cross_border_eu == true
      assert tx.reverse_charge == true
      assert tx.tax_treatment == :reverse_charge
      assert tx.vat_rate == 0
      assert tx.invoice_note == "VAT reverse charge applies..."
    end

    test "tax_treatment types are atoms" do
      tx = %Transaction{tax_treatment: :domestic}
      assert tx.tax_treatment == :domestic

      tx = %Transaction{tax_treatment: :reverse_charge}
      assert tx.tax_treatment == :reverse_charge

      tx = %Transaction{tax_treatment: :export}
      assert tx.tax_treatment == :export
    end
  end
end
