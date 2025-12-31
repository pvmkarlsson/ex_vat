defmodule ExVat.TEDB.Categories do
  @moduledoc """
  All VAT rate categories from the EU TEDB (Taxes in Europe Database).

  These categories are defined in the EU VAT Directive and used to query
  reduced/special VAT rates from the TEDB API.

  ## Usage

      # List all categories
      ExVat.TEDB.Categories.all()

      # Search categories
      ExVat.TEDB.Categories.search("food")
      #=> [{"FOODSTUFFS", "Foodstuffs (including beverages...)"}]

      # Get category by ID
      ExVat.TEDB.Categories.get("FOODSTUFFS")
      #=> %{id: "FOODSTUFFS", description: "...", group: :essentials}

      # List by group
      ExVat.TEDB.Categories.by_group(:healthcare)
  """

  @type category :: %{
          id: String.t(),
          description: String.t(),
          group: atom()
        }

  # All TEDB categories from the official specification
  # Grouped by logical area for easier navigation
  @categories [
    # Food & Beverages
    %{id: "FOODSTUFFS", description: "Foodstuffs (including beverages but excluding alcoholic beverages) for human and animal consumption; live animals, seeds, plants", group: :food},
    %{id: "RESTAURANT", description: "Restaurant and catering services, excluding services involving alcoholic beverages", group: :food},
    %{id: "CANTEEN_FOOD_SUPPLY", description: "Supply of food and drink in company and staff canteens, school canteens and food pantries", group: :food},
    %{id: "WINE", description: "Wine from fresh grapes", group: :food},
    %{id: "WINE_FRESH_GRAPE", description: "Wine of fresh grapes containing 13° or less of alcohol", group: :food},
    %{id: "WINE_TABLE", description: "Common table wines", group: :food},
    %{id: "SUPPLY_WATER", description: "Supply of water", group: :food},

    # Healthcare & Pharmaceutical
    %{id: "PHARMACEUTICAL_PRODUCTS", description: "Pharmaceutical products used for medical and veterinary purposes, including contraception and female sanitary protection", group: :healthcare},
    %{id: "MEDICAL_EQUIPMENT", description: "Medical equipment, appliances, devices for healthcare or disabled use, including health protection masks", group: :healthcare},
    %{id: "MEDICAL_CARE", description: "Provision of medical and dental care and thermal treatment", group: :healthcare},
    %{id: "VETERINARY_SERVICES", description: "Services supplied by veterinary surgeons", group: :healthcare},

    # Books & Publications
    %{id: "BOOKS", description: "Books on physical means of support or electronically supplied", group: :publications},
    %{id: "NEWSPAPERS", description: "Newspapers", group: :publications},
    %{id: "PERIODICALS", description: "Periodicals", group: :publications},
    %{id: "PERIODICALS_PRODUCTION", description: "Production of periodicals", group: :publications},
    %{id: "LOAN_LIBRARIES", description: "Supply including loan by libraries of books, newspapers and periodicals", group: :publications},
    %{id: "PRINTED_ADVERTISING_MATERIAL", description: "Printed advertising material, trade catalogues and tourist propaganda publications", group: :publications},

    # Accommodation & Housing
    %{id: "ACCOMMODATION", description: "Accommodation in hotels and similar establishments, holiday accommodation, camping sites", group: :housing},
    %{id: "HOLIDAY_ACCOMMODATION", description: "Transient accommodation and letting of holiday camps or camping sites", group: :housing},
    %{id: "HOUSING_PROVISION", description: "Supply and construction of housing as part of social policy; renovation and repairing", group: :housing},
    %{id: "HOUSING", description: "Immovable goods for residential purposes", group: :housing},
    %{id: "NON_HOUSING", description: "Immovable goods for non-residential purposes", group: :housing},
    %{id: "NON_SOCIAL_HOUSING", description: "Housing not being part of social policy", group: :housing},
    %{id: "NON_LUXURY_HOUSING", description: "Supply and construction of non-luxury housing", group: :housing},
    %{id: "NON_LUXURY_DWELLING_SUPPLY", description: "Supply and construction of certain non-luxury private dwellings", group: :housing},
    %{id: "PROTECTED_HOUSING_SUPPLY", description: "Supply of housing classified as officially protected", group: :housing},
    %{id: "COOPERATIVE_HOUSING_ALLOCATION", description: "Allocations of residential property by housing cooperatives", group: :housing},
    %{id: "MOBILE_HOME", description: "Caravan or mobile home for use as residence", group: :housing},
    %{id: "LETTING", description: "Letting", group: :housing},
    %{id: "DWELLING_RENTAL", description: "Assignment of dwelling for use as principal residence undergoing renovation", group: :housing},

    # Construction & Renovation
    %{id: "CONSTRUCTION", description: "Supply and construction", group: :construction},
    %{id: "CONSTRUCTION_CONTRACT_SERVICES", description: "Services supplied under specific contracts relating to construction of buildings", group: :construction},
    %{id: "CONSTRUCTION_GOOD", description: "Goods for construction of certain buildings", group: :construction},
    %{id: "CONCRETE_WORK", description: "Concrete works", group: :construction},
    %{id: "RENOVATION", description: "Renovation, alteration and repair", group: :construction},
    %{id: "RENOVATION_WORK", description: "Certain renovation works", group: :construction},
    %{id: "RESIDENTIAL_RENOVATION", description: "Renovation work for dwelling used as principal residence by owner", group: :construction},
    %{id: "NON_OWNED_RESIDENCY_RENOVATION", description: "Renovation work for dwelling used by non-owner", group: :construction},
    %{id: "PRIVATE_DWELLINGS", description: "Renovation and repairing of public and other buildings for public interest", group: :construction},
    %{id: "RENOVATED_BUILDING_SALE", description: "Supply of renovated buildings sold by undertakings that did the work", group: :construction},
    %{id: "FARMHOUSE_CONSTRUCTION", description: "Supply and construction of certain rural houses used by farmers", group: :construction},
    %{id: "ACCESSIBILITY_SERVICES", description: "Services for overcoming or removing architectural barriers", group: :construction},

    # Transport
    %{id: "TRANSPORT_PASSENGERS", description: "Transport of passengers and goods accompanying them (luggage, bicycles, vehicles)", group: :transport},

    # Energy & Utilities
    %{id: "SUPPLY_ELECTRICITY", description: "Electricity", group: :energy},
    %{id: "SUPPLY_GAS", description: "Natural gas (until 1 January 2030)", group: :energy},
    %{id: "SUPPLY_HEATING", description: "District heating and district cooling", group: :energy},
    %{id: "HEAT_COOLING_STEAM", description: "Heat, cooling and steam, except certain heating networks", group: :energy},
    %{id: "SUSTAINABLE_ENERGY", description: "Electricity, district heating/cooling, biogas; highly efficient low emissions heating systems", group: :energy},
    %{id: "BIOGAS", description: "Biogas produced by the feedstock", group: :energy},
    %{id: "LOW_EMISSION_HEATING", description: "Highly efficient low emissions heating systems", group: :energy},
    %{id: "SOLAR_PANELS", description: "Supply and installation of solar panels on dwellings and public buildings", group: :energy},
    %{id: "SPECIFIC_ENERGY", description: "Specific energy products", group: :energy},
    %{id: "FOSSIL_FUEL", description: "Until 1 January 2030: Fossil fuels", group: :energy},
    %{id: "COAL_FUEL", description: "Coal and solid fuels; lignite; coke and semi-coke; petroleum coke used as fuel", group: :energy},
    %{id: "FUEL_MINERAL_OIL", description: "Solid mineral fuels; mineral oils and wood for use as fuel", group: :energy},
    %{id: "PETROLEUM_FUEL", description: "Coloured and marked petroleum and gas oil and fuel oil", group: :energy},
    %{id: "WOOD", description: "Until 1 January 2030: Wood used as firewood", group: :energy},
    %{id: "WOOD_ARTICLE98", description: "Wood used as firewood (until 1 January 2030)", group: :energy},
    %{id: "GREENHOUSE_GAS", description: "Until 1 January 2030: Other goods with similar impact on greenhouse gas emissions, such as peat", group: :energy},

    # Culture & Entertainment
    %{id: "CULTURAL_EVENTS", description: "Admission to shows, theatres, circuses, fairs, concerts, museums, zoos, cinemas, exhibitions", group: :culture},
    %{id: "THEATRE_PERFORMANCES", description: "140 first theatre and circus performances", group: :culture},
    %{id: "EVENT_ACCESS", description: "Granting of access to certain events and premises", group: :culture},
    %{id: "EVENTS_ADMISSION", description: "Admission to events", group: :culture},
    %{id: "EVENTS_ADMISSION_LIVE", description: "Access to live-streaming of events", group: :culture},

    # Sports
    %{id: "SPORTING_EVENTS", description: "Admission to sporting events or live-streaming; use of sporting facilities; sport classes", group: :sports},
    %{id: "ADMISSION_SPORTING_EVENTS", description: "Admission to sporting events", group: :sports},
    %{id: "LIVE_STREAMING_SPORTING_EVENTS", description: "Access to live-streaming of sporting events", group: :sports},
    %{id: "SPORTING_FACILITIES", description: "Use of sporting facilities", group: :sports},
    %{id: "SPORTING_FACILITY_ACCESS", description: "Granting the right of access to and use of sports facilities", group: :sports},

    # Broadcasting & Internet
    %{id: "BROADCASTING_SERVICES", description: "Reception of radio and television broadcasting and webcasting by media service provider; internet access for digitalisation", group: :broadcasting},
    %{id: "RADIO_TV_BROADCASTING", description: "Radio and television broadcasting/webcasting", group: :broadcasting},
    %{id: "RADIO_BROADCASTING_SUBSCRIPTION", description: "Subscription to certain radio broadcasting services", group: :broadcasting},
    %{id: "CERTAIN_BROADCASTING_SERVICES", description: "Reception of certain radio and television broadcasting services", group: :broadcasting},
    %{id: "PUBLIC_BROADCASTING", description: "Contribution to public broadcasting", group: :broadcasting},
    %{id: "INTERNET_ACCESS", description: "Internet access", group: :broadcasting},

    # Children & Family
    %{id: "CHILDREN_CLOTHING_FOOTWEAR", description: "Children's clothing and footwear; supply of children's car seats", group: :children},
    %{id: "CHILDREN_CLOTHING", description: "Children's clothing and footwear", group: :children},
    %{id: "CHILDREN_FOOTWEAR", description: "Children's clothing and footwear", group: :children},
    %{id: "CHILD_WEAR", description: "Clothing, headgear, scarves, gloves and shoes for children under 14", group: :children},
    %{id: "CHILDREN_CAR_SEATS", description: "Children's car seats", group: :children},

    # Agriculture
    %{id: "AGRICULTURAL_INPUT", description: "Agricultural input", group: :agriculture},
    %{id: "AGRICULTURAL_PRODUCTION", description: "Supply of goods and services for agricultural production excluding capital goods", group: :agriculture},
    %{id: "AGRICULTURAL_EQUIPMENT", description: "Certain agricultural tools and equipment", group: :agriculture},
    %{id: "CERTAIN_AGRICULTURAL_INPUT", description: "Certain agricultural inputs", group: :agriculture},
    %{id: "ORGANIC_AGRICULTURE_SUPPLY", description: "Supplies of fertilisers and organisms for organic pest management", group: :agriculture},
    %{id: "CHEMICAL_FERTILISERS", description: "Until 1 January 2032: Chemical fertilisers", group: :agriculture},
    %{id: "CHEMICAL_PESTICIDES", description: "Chemical pesticides and fertilisers (until 1 January 2032)", group: :agriculture},
    %{id: "CHEMICAL_PESTICIDES_ENVIRONMENT", description: "Until 1 January 2032: Chemical pesticides", group: :agriculture},
    %{id: "PLANT", description: "Live plants and floricultural products, including bulbs, cut flowers and ornamental foliage", group: :agriculture},

    # Art & Collectibles
    %{id: "ANTIQUES", description: "Supply of works of art, collectors' items and antiques", group: :art},
    %{id: "100_YEARS_OLD", description: "Goods more than 100 years old (CN code 9706 00 00)", group: :art},
    %{id: "PICTURES", description: "Pictures, collages, paintings and drawings executed entirely by hand by the artist", group: :art},
    %{id: "SCULPTURES", description: "Original sculptures and statuary in any material executed entirely by the artist", group: :art},
    %{id: "SCULPTURE_CASTS", description: "Sculpture casts limited to eight copies supervised by the artist", group: :art},
    %{id: "TAPESTRIES", description: "Tapestries and wall textiles made by hand from original designs", group: :art},
    %{id: "CERAMICS", description: "Individual pieces of ceramics executed entirely by the artist and signed", group: :art},
    %{id: "ENAMELS", description: "Enamels on copper executed entirely by hand, limited to eight numbered copies", group: :art},
    %{id: "PHOTOGRAPHS", description: "Photographs taken by the artist, printed by him, signed and numbered, limited to 30 copies", group: :art},
    %{id: "IMPRESSIONS", description: "Original engravings, prints and lithographs in limited numbers", group: :art},
    %{id: "ZOOLOGICAL", description: "Collections of zoological, botanical, mineralogical, ethnographic or numismatic interest", group: :art},
    %{id: "POSTAGE", description: "Postage or revenue stamps, postmarks, first-day covers, pre-stamped stationery", group: :art},

    # Personal Services
    %{id: "HAIRDRESSING", description: "Hairdressing", group: :services},
    %{id: "BODY_CARE_SERVICES", description: "Certain services consisting of the care of the human body", group: :services},
    %{id: "DOMESTIC_CARE", description: "Domestic care services such as home help and care of young, elderly, sick or disabled", group: :services},
    %{id: "CARE_SERVICES_DEPENDENT", description: "Telecare, home help, day/night centre and residential care for dependent people", group: :services},
    %{id: "WINDOW_CLEANING", description: "Window cleaning and cleaning in private households", group: :services},
    %{id: "FUNERAL", description: "Services provided by undertakers and cremators", group: :services},
    %{id: "UNDERTAKERS_SERVICES", description: "Supply of services by undertakers and cremation services, and related goods", group: :services},

    # Repair Services
    %{id: "REPAIR_SERVICES", description: "Certain repair and related services", group: :repairs},
    %{id: "REPAIRING_SERVICES", description: "Supply of repairing services of household appliances, shoes, leather goods, clothing", group: :repairs},
    %{id: "CLOTHING_REPAIR", description: "Clothing and household linen", group: :repairs},
    %{id: "SHOES_REPAIR", description: "Shoes and leather goods", group: :repairs},
    %{id: "HOUSEHOLD", description: "Household appliances", group: :repairs},
    %{id: "BICYCLES_REPAIR", description: "Minor repairs of bicycles", group: :repairs},

    # Bicycles
    %{id: "BICYCLES_SUPPLY", description: "Supply of bicycles including electric bicycles; rental and repairing services", group: :bicycles},
    %{id: "BICYCLES_ELECTRIC", description: "Bicycles, including electric bicycles", group: :bicycles},
    %{id: "BICYCLES_RENTAL", description: "Rental and repair of bicycles", group: :bicycles},

    # Equine & Animals
    %{id: "LIVE_EQUINES", description: "Live equines and the supply services related to live equines", group: :animals},
    %{id: "LIVE_GREYHOUNDS", description: "Supply of live greyhounds", group: :animals},
    %{id: "GREYHOUND_INSEMINATION_SERVICES", description: "Supply of insemination services for greyhounds", group: :animals},
    %{id: "JOCKEY_SERVICES", description: "Services supplied by jockeys", group: :animals},

    # Professional Services
    %{id: "WRITERS_SERVICES", description: "Supply of services by writers, composers and performing artists, or royalties", group: :professional},
    %{id: "WRITERS_SERVICES_NEW", description: "Services of writers, etc.", group: :professional},
    %{id: "WRITERS_ROYALTIES", description: "Royalties to writers, etc.", group: :professional},
    %{id: "ROYALTIES", description: "Services provided by writers, composers and performers and royalties due to them", group: :professional},
    %{id: "LEGAL_SERVICES", description: "Legal services for people in labour court proceedings and under legal aid scheme", group: :professional},
    %{id: "TOUR_GUIDE_SERVICES", description: "Services supplied by tour guides", group: :professional},
    %{id: "DRIVING_INSTRUCTION", description: "Instruction in the driving of mechanically propelled road vehicles", group: :professional},

    # Social & Welfare
    %{id: "SOCIAL_WELLBEING", description: "Supply of goods and services by organisations engaged in welfare or social security work", group: :social},
    %{id: "RESCUE_EQUIPMENT", description: "Tools and equipment for rescue or first aid services for public bodies or non-profits", group: :social},
    %{id: "MARINE_SAFETY_SERVICES", description: "Lightships, lighthouses, lifeboat services, navigational aids", group: :social},
    %{id: "NAVIGATIONAL_AID_SERVICES", description: "Supply of services in connection with lightships, lighthouses, navigational aids, life-saving", group: :social},

    # Financial Services
    %{id: "CREDIT_MANAGEMENT", description: "Management of credits and credit guarantees by non-granters", group: :financial},
    %{id: "SECURITY_MANAGEMENT", description: "Custody and management of securities", group: :financial},

    # Waste & Environment
    %{id: "STREET_CLEANING", description: "Supply of services for sewage, street cleaning, refuse collection and waste treatment/recycling", group: :environment},
    %{id: "WASTE_TREATMENT", description: "Sewage disposal and treatment and emptying of septic tanks and industrial tanks", group: :environment},
    %{id: "WASTE_TREATMENT_REFUSAL", description: "Refuse collection and waste treatment", group: :environment},
    %{id: "CLEANING_PRODUCT", description: "Washing and cleaning preparations", group: :environment},

    # Photography & Media
    %{id: "PHOTOGRAPHIC_SUPPLY", description: "Photographic and related supplies", group: :media},

    # Hiring
    %{id: "HIRING_SHORT_PERIOD", description: "Hiring for short period", group: :hiring},

    # Special/Temporary Rates
    %{id: "REGION", description: "Special reduced rate for specific regions", group: :special},
    %{id: "TEMPORARY", description: "Special temporary reduced rates (Articles 104a, 105, 112, 113, 115, 117, 122 of VAT Directive)", group: :special},
    %{id: "PARKING", description: "Temporary Parking Rates (Articles 118 and 119 of VAT Directive)", group: :special},
    %{id: "NEW_PARKING_RATE", description: "Parking rates (Article 105a(3) of VAT Directive)", group: :special},
    %{id: "SUPER_TEMPORARY", description: "Temporary Super-reduced Rates (Articles 110 and 114 of VAT Directive)", group: :special},
    %{id: "EXEMPTION_SUPERREDUCED", description: "Exemptions and super-reduced rates (Article 105a(1) of VAT Directive)", group: :special},
    %{id: "TEMPORARY_EXEMPTION_RATE", description: "Temporary Exemptions, super-reduced or reduced rates (Article 105a(2) of VAT Directive)", group: :special},
    %{id: "ZERO_RATE", description: "Zero Rate: Article 37 of the VAT Directive", group: :special},
    %{id: "ZERO_REDUCED_RATE", description: "Zero and Reduced Rates: Articles 109-122 (Title VIII, Chapter 4) of VAT directive", group: :special}
  ]

  @categories_by_id Map.new(@categories, fn c -> {c.id, c} end)
  @category_ids Enum.map(@categories, & &1.id)

  @groups [
    :food,
    :healthcare,
    :publications,
    :housing,
    :construction,
    :transport,
    :energy,
    :culture,
    :sports,
    :broadcasting,
    :children,
    :agriculture,
    :art,
    :services,
    :repairs,
    :bicycles,
    :animals,
    :professional,
    :social,
    :financial,
    :environment,
    :media,
    :hiring,
    :special
  ]

  @doc """
  Returns all category IDs.

  ## Examples

      ExVat.TEDB.Categories.ids()
      #=> ["100_YEARS_OLD", "ACCOMMODATION", "ADMISSION_SPORTING_EVENTS", ...]
  """
  @spec ids() :: [String.t()]
  def ids, do: @category_ids

  @doc """
  Returns all categories with full details.

  ## Examples

      ExVat.TEDB.Categories.all()
      #=> [%{id: "FOODSTUFFS", description: "...", group: :food}, ...]
  """
  @spec all() :: [category()]
  def all, do: @categories

  @doc """
  Returns all available groups.

  ## Examples

      ExVat.TEDB.Categories.groups()
      #=> [:food, :healthcare, :publications, :housing, ...]
  """
  @spec groups() :: [atom()]
  def groups, do: @groups

  @doc """
  Gets a category by ID.

  ## Examples

      ExVat.TEDB.Categories.get("FOODSTUFFS")
      #=> %{id: "FOODSTUFFS", description: "...", group: :food}

      ExVat.TEDB.Categories.get("INVALID")
      #=> nil
  """
  @spec get(String.t()) :: category() | nil
  def get(id) when is_binary(id) do
    Map.get(@categories_by_id, String.upcase(id))
  end

  @doc """
  Checks if a category ID exists.

  ## Examples

      ExVat.TEDB.Categories.exists?("FOODSTUFFS")
      #=> true

      ExVat.TEDB.Categories.exists?("INVALID")
      #=> false
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(id) when is_binary(id) do
    Map.has_key?(@categories_by_id, String.upcase(id))
  end

  @doc """
  Returns categories filtered by group.

  ## Examples

      ExVat.TEDB.Categories.by_group(:food)
      #=> [%{id: "FOODSTUFFS", ...}, %{id: "RESTAURANT", ...}, ...]

      ExVat.TEDB.Categories.by_group(:healthcare)
      #=> [%{id: "PHARMACEUTICAL_PRODUCTS", ...}, ...]
  """
  @spec by_group(atom()) :: [category()]
  def by_group(group) when is_atom(group) do
    Enum.filter(@categories, fn c -> c.group == group end)
  end

  @doc """
  Searches categories by ID or description.

  Case-insensitive search that matches partial strings.

  ## Examples

      ExVat.TEDB.Categories.search("food")
      #=> [%{id: "FOODSTUFFS", ...}, %{id: "CANTEEN_FOOD_SUPPLY", ...}]

      ExVat.TEDB.Categories.search("book")
      #=> [%{id: "BOOKS", ...}]

      ExVat.TEDB.Categories.search("electric")
      #=> [%{id: "SUPPLY_ELECTRICITY", ...}, %{id: "BICYCLES_ELECTRIC", ...}]
  """
  @spec search(String.t()) :: [category()]
  def search(query) when is_binary(query) do
    query_down = String.downcase(query)

    Enum.filter(@categories, fn c ->
      String.contains?(String.downcase(c.id), query_down) ||
        String.contains?(String.downcase(c.description), query_down)
    end)
  end

  @doc """
  Returns a simplified map of category ID to description.

  Useful for display purposes.

  ## Examples

      ExVat.TEDB.Categories.to_map()
      #=> %{"FOODSTUFFS" => "Foodstuffs...", "RESTAURANT" => "Restaurant..."}
  """
  @spec to_map() :: %{String.t() => String.t()}
  def to_map do
    Map.new(@categories, fn c -> {c.id, c.description} end)
  end

  @doc """
  Returns common/frequently used categories.

  These are the most commonly needed categories for typical e-commerce.

  ## Examples

      ExVat.TEDB.Categories.common()
      #=> [%{id: "FOODSTUFFS", ...}, %{id: "BOOKS", ...}, ...]
  """
  @spec common() :: [category()]
  def common do
    common_ids = [
      "FOODSTUFFS",
      "RESTAURANT",
      "ACCOMMODATION",
      "BOOKS",
      "NEWSPAPERS",
      "PERIODICALS",
      "PHARMACEUTICAL_PRODUCTS",
      "MEDICAL_EQUIPMENT",
      "TRANSPORT_PASSENGERS",
      "SUPPLY_ELECTRICITY",
      "SUPPLY_GAS",
      "SUPPLY_WATER",
      "CHILDREN_CLOTHING_FOOTWEAR",
      "CULTURAL_EVENTS",
      "SPORTING_EVENTS",
      "HOUSING_PROVISION"
    ]

    Enum.filter(@categories, fn c -> c.id in common_ids end)
  end
end
