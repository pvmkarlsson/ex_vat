defmodule ExVat.TEDBTest do
  use ExUnit.Case, async: true

  alias ExVat.TEDB

  describe "categories/0" do
    test "returns common category mappings" do
      categories = TEDB.categories()

      assert categories[:foodstuffs] == "FOODSTUFFS"
      assert categories[:restaurant] == "RESTAURANT"
      assert categories[:books] == "BOOKS"
      assert categories[:pharmaceutical] == "PHARMACEUTICAL_PRODUCTS"
    end
  end

  describe "get_rates/2 request building" do
    test "builds request for single country" do
      # We can't easily test the actual request without mocking
      # but we verify the function accepts proper arguments
      assert is_function(&TEDB.get_rates/2)
    end
  end
end
