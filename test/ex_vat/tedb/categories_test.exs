defmodule ExVat.TEDB.CategoriesTest do
  use ExUnit.Case, async: true

  alias ExVat.TEDB.Categories

  describe "ids/0" do
    test "returns list of category IDs" do
      ids = Categories.ids()

      assert is_list(ids)
      assert length(ids) > 100
      assert "FOODSTUFFS" in ids
      assert "BOOKS" in ids
      assert "RESTAURANT" in ids
    end
  end

  describe "all/0" do
    test "returns list of category maps" do
      categories = Categories.all()

      assert is_list(categories)
      assert length(categories) > 100

      first = hd(categories)
      assert Map.has_key?(first, :id)
      assert Map.has_key?(first, :description)
      assert Map.has_key?(first, :group)
    end
  end

  describe "groups/0" do
    test "returns list of group atoms" do
      groups = Categories.groups()

      assert is_list(groups)
      assert :food in groups
      assert :healthcare in groups
      assert :energy in groups
    end
  end

  describe "get/1" do
    test "returns category by ID" do
      cat = Categories.get("FOODSTUFFS")

      assert cat.id == "FOODSTUFFS"
      assert cat.group == :food
      assert String.contains?(cat.description, "Foodstuffs")
    end

    test "returns nil for invalid ID" do
      assert Categories.get("INVALID_CATEGORY") == nil
    end

    test "is case-insensitive" do
      assert Categories.get("foodstuffs") != nil
      assert Categories.get("FoodStuffs") != nil
    end
  end

  describe "exists?/1" do
    test "returns true for valid category" do
      assert Categories.exists?("FOODSTUFFS") == true
      assert Categories.exists?("BOOKS") == true
    end

    test "returns false for invalid category" do
      assert Categories.exists?("INVALID") == false
    end
  end

  describe "by_group/1" do
    test "returns categories for a group" do
      food_cats = Categories.by_group(:food)

      assert is_list(food_cats)
      assert food_cats != []

      ids = Enum.map(food_cats, & &1.id)
      assert "FOODSTUFFS" in ids
      assert "RESTAURANT" in ids
    end

    test "returns empty list for invalid group" do
      assert Categories.by_group(:invalid_group) == []
    end
  end

  describe "search/1" do
    test "searches by ID" do
      results = Categories.search("FOOD")

      assert results != []

      ids = Enum.map(results, & &1.id)
      assert "FOODSTUFFS" in ids
    end

    test "searches by description" do
      results = Categories.search("pharmaceutical")

      assert results != []

      ids = Enum.map(results, & &1.id)
      assert "PHARMACEUTICAL_PRODUCTS" in ids
    end

    test "is case-insensitive" do
      results1 = Categories.search("book")
      results2 = Categories.search("BOOK")
      results3 = Categories.search("Book")

      assert results1 == results2
      assert results2 == results3
    end

    test "returns empty list for no matches" do
      assert Categories.search("xyznonexistent") == []
    end
  end

  describe "common/0" do
    test "returns common categories" do
      common = Categories.common()

      assert is_list(common)
      assert length(common) > 10

      ids = Enum.map(common, & &1.id)
      assert "FOODSTUFFS" in ids
      assert "BOOKS" in ids
      assert "ACCOMMODATION" in ids
    end
  end

  describe "to_map/0" do
    test "returns map of ID to description" do
      map = Categories.to_map()

      assert is_map(map)
      assert Map.has_key?(map, "FOODSTUFFS")
      assert is_binary(map["FOODSTUFFS"])
    end
  end
end
