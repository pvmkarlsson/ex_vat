defmodule ExVat.TARICTest do
  use ExUnit.Case, async: true

  alias ExVat.TARIC

  describe "valid_cn_code?/1" do
    test "returns true for valid codes" do
      assert TARIC.valid_cn_code?("01") == true
      assert TARIC.valid_cn_code?("0101") == true
      assert TARIC.valid_cn_code?("01012910") == true
      assert TARIC.valid_cn_code?("9706000000") == true
    end

    test "returns true for codes with spaces/dots" do
      assert TARIC.valid_cn_code?("0101 29 10") == true
      assert TARIC.valid_cn_code?("9706.00.00") == true
    end

    test "returns false for invalid codes" do
      assert TARIC.valid_cn_code?("abc") == false
      assert TARIC.valid_cn_code?("") == false
      assert TARIC.valid_cn_code?("1") == false
      assert TARIC.valid_cn_code?("12345678901") == false
    end

    test "returns false for non-strings" do
      assert TARIC.valid_cn_code?(nil) == false
      assert TARIC.valid_cn_code?(123) == false
    end
  end

  describe "normalize_cn_code/1" do
    test "removes spaces and pads to 10 digits" do
      assert TARIC.normalize_cn_code("0101 29 10") == "0101291000"
    end

    test "removes dots and pads to 10 digits" do
      assert TARIC.normalize_cn_code("9706.00.00") == "9706000000"
    end

    test "removes both and pads" do
      assert TARIC.normalize_cn_code("97 06.00 00") == "9706000000"
    end

    test "pads short codes to 10 digits" do
      assert TARIC.normalize_cn_code("0101") == "0101000000"
      assert TARIC.normalize_cn_code("01") == "0100000000"
    end

    test "keeps already 10-digit codes" do
      assert TARIC.normalize_cn_code("0101291000") == "0101291000"
    end
  end
end
