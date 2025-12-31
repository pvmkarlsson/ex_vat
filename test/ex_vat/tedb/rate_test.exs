defmodule ExVat.TEDB.RateTest do
  use ExUnit.Case, async: true

  alias ExVat.TEDB.Rate

  describe "standard?/1" do
    test "returns true for standard rate" do
      rate = %Rate{type: :standard, rate: 25.0, country: "SE"}
      assert Rate.standard?(rate) == true
    end

    test "returns false for non-standard rates" do
      assert Rate.standard?(%Rate{type: :reduced, rate: 12.0, country: "SE"}) == false
      assert Rate.standard?(%Rate{type: :super_reduced, rate: 6.0, country: "SE"}) == false
      assert Rate.standard?(%Rate{type: :zero, rate: 0.0, country: "SE"}) == false
    end
  end

  describe "reduced?/1" do
    test "returns true for reduced rate types" do
      assert Rate.reduced?(%Rate{type: :reduced, rate: 12.0, country: "SE"}) == true
      assert Rate.reduced?(%Rate{type: :super_reduced, rate: 4.0, country: "ES"}) == true
      assert Rate.reduced?(%Rate{type: :parking, rate: 13.0, country: "BE"}) == true
    end

    test "returns false for non-reduced rates" do
      assert Rate.reduced?(%Rate{type: :standard, rate: 25.0, country: "SE"}) == false
      assert Rate.reduced?(%Rate{type: :zero, rate: 0.0, country: "SE"}) == false
      assert Rate.reduced?(%Rate{type: :exempt, rate: nil, country: "SE"}) == false
    end
  end

  describe "zero_or_exempt?/1" do
    test "returns true for zero type" do
      assert Rate.zero_or_exempt?(%Rate{type: :zero, rate: 0.0, country: "SE"}) == true
    end

    test "returns true for exempt type" do
      assert Rate.zero_or_exempt?(%Rate{type: :exempt, rate: nil, country: "SE"}) == true
    end

    test "returns true for zero rate value" do
      assert Rate.zero_or_exempt?(%Rate{type: :reduced, rate: 0, country: "SE"}) == true
      assert Rate.zero_or_exempt?(%Rate{type: :reduced, rate: 0.0, country: "SE"}) == true
    end

    test "returns false for non-zero rates" do
      assert Rate.zero_or_exempt?(%Rate{type: :standard, rate: 25.0, country: "SE"}) == false
      assert Rate.zero_or_exempt?(%Rate{type: :reduced, rate: 12.0, country: "SE"}) == false
    end
  end
end
