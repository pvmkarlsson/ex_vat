defmodule ExVat.TARIC.GoodsTest do
  use ExUnit.Case, async: true

  alias ExVat.TARIC.Goods
  alias ExVat.TEDB.Rate

  describe "format_cn_code/1" do
    test "formats 10-digit code correctly" do
      assert Goods.format_cn_code("9706000000") == "9706 00 00 00"
      assert Goods.format_cn_code("0101291000") == "0101 29 10 00"
    end

    test "pads and formats shorter codes" do
      assert Goods.format_cn_code("0101") == "0101 00 00 00"
      assert Goods.format_cn_code("97") == "9700 00 00 00"
    end
  end

  describe "chapter/1" do
    test "returns first 2 digits from code string" do
      assert Goods.chapter("9706000000") == "97"
      assert Goods.chapter("0101291000") == "01"
    end

    test "returns first 2 digits from Goods struct" do
      goods = %Goods{cn_code: "9706000000", description: "test", language: "EN"}
      assert Goods.chapter(goods) == "97"
    end
  end

  describe "heading/1" do
    test "returns first 4 digits from code string" do
      assert Goods.heading("9706000000") == "9706"
      assert Goods.heading("0101291000") == "0101"
    end

    test "returns first 4 digits from Goods struct" do
      goods = %Goods{cn_code: "9706000000", description: "test", language: "EN"}
      assert Goods.heading(goods) == "9706"
    end
  end

  describe "has_reduced_rate?/1" do
    test "returns true when reduced rate exists" do
      goods = %Goods{
        cn_code: "9706000000",
        description: "Antiques",
        language: "EN",
        country: "DE",
        rates: [
          %Rate{type: :standard, rate: 19.0, country: "DE"},
          %Rate{type: :reduced, rate: 7.0, country: "DE"}
        ]
      }

      assert Goods.has_reduced_rate?(goods) == true
    end

    test "returns false when no reduced rate" do
      goods = %Goods{
        cn_code: "9706000000",
        description: "Antiques",
        language: "EN",
        country: "DE",
        rates: [
          %Rate{type: :standard, rate: 19.0, country: "DE"}
        ]
      }

      assert Goods.has_reduced_rate?(goods) == false
    end

    test "returns false when rates is nil" do
      goods = %Goods{cn_code: "9706000000", description: "test", language: "EN"}
      assert Goods.has_reduced_rate?(goods) == false
    end
  end

  describe "lowest_rate/1" do
    test "returns lowest rate when multiple rates exist" do
      goods = %Goods{
        cn_code: "9706000000",
        description: "Antiques",
        language: "EN",
        country: "DE",
        rates: [
          %Rate{type: :standard, rate: 19.0, country: "DE"},
          %Rate{type: :reduced, rate: 7.0, country: "DE"},
          %Rate{type: :super_reduced, rate: 4.0, country: "DE"}
        ]
      }

      assert Goods.lowest_rate(goods) == 4.0
    end

    test "returns nil when rates is nil" do
      goods = %Goods{cn_code: "9706000000", description: "test", language: "EN"}
      assert Goods.lowest_rate(goods) == nil
    end

    test "returns nil when rates is empty" do
      goods = %Goods{cn_code: "9706000000", description: "test", language: "EN", rates: []}
      assert Goods.lowest_rate(goods) == nil
    end

    test "handles rates with nil values" do
      goods = %Goods{
        cn_code: "9706000000",
        description: "Antiques",
        language: "EN",
        country: "DE",
        rates: [
          %Rate{type: :standard, rate: 19.0, country: "DE"},
          %Rate{type: :exempt, rate: nil, country: "DE"}
        ]
      }

      assert Goods.lowest_rate(goods) == 19.0
    end
  end
end
