defmodule ExVat.TEDB do
  @moduledoc """
  Client for the EU TEDB (Taxes in Europe Database) SOAP API.

  Retrieves VAT rates for EU member states by category, CN code, or CPA code.

  ## Endpoint

  `https://ec.europa.eu/taxation_customs/tedb/ws/`

  ## Features

  - Standard and reduced VAT rates by country
  - Category-specific rates (FOODSTUFFS, RESTAURANT, ACCOMMODATION, etc.)
  - CN code rates (goods)
  - CPA code rates (services)
  - Historical rates by date range

  ## Usage

      # Get all rates for a country
      {:ok, rates} = ExVat.TEDB.get_rates("SE")

      # Get rates for specific category
      {:ok, rates} = ExVat.TEDB.get_rates("SE", categories: ["FOODSTUFFS"])

      # Get rates for a date range
      {:ok, rates} = ExVat.TEDB.get_rates("SE", from: ~D[2024-01-01], to: ~D[2024-12-31])

  ## Error Handling

  Functions return `{:error, reason}` where reason can be:

    * `:parse_error` - Failed to parse the XML response
    * `:no_standard_rate` - No standard rate found for the country
    * `:timeout` - Request timed out
    * `%{code: String.t(), description: String.t()}` - SOAP fault from the API
    * Other atoms for HTTP/network errors (`:econnrefused`, etc.)
  """

  require Logger

  alias ExVat.TEDB.Rate

  @tedb_endpoint "https://ec.europa.eu/taxation_customs/tedb/ws/"
  @soap_action "urn:ec.europa.eu:taxud:tedb:services:v1:VatRetrievalService/RetrieveVatRates"
  @namespace "urn:ec.europa.eu:taxud:tedb:services:v1:IVatRetrievalService"
  @types_namespace "urn:ec.europa.eu:taxud:tedb:services:v1:IVatRetrievalService:types"

  # Common rate categories
  @categories %{
    foodstuffs: "FOODSTUFFS",
    restaurant: "RESTAURANT",
    accommodation: "ACCOMMODATION",
    books: "BOOKS",
    newspapers: "NEWSPAPERS",
    pharmaceutical: "PHARMACEUTICAL_PRODUCTS",
    medical_equipment: "MEDICAL_EQUIPMENT",
    transport: "TRANSPORT_PASSENGERS",
    cultural_events: "CULTURAL_EVENTS",
    sporting_events: "SPORTING_EVENTS",
    children_clothing: "CHILDREN_CLOTHING_FOOTWEAR",
    housing: "HOUSING_PROVISION",
    electricity: "SUPPLY_ELECTRICITY",
    gas: "SUPPLY_GAS",
    water: "SUPPLY_WATER",
    heating: "SUPPLY_HEATING"
  }

  @doc """
  Returns map of common category atoms to TEDB identifiers.
  """
  @spec categories() :: %{atom() => String.t()}
  def categories, do: @categories

  @doc """
  Retrieves VAT rates from TEDB.

  ## Options

    * `:countries` - List of country codes (default: all EU countries)
    * `:categories` - List of category identifiers (see `categories/0`)
    * `:cn_codes` - List of CN codes (goods)
    * `:cpa_codes` - List of CPA codes (services)
    * `:from` - Start date for rate applicability
    * `:to` - End date for rate applicability (default: today)
    * `:timeout` - Request timeout in ms (default: 30000)

  ## Examples

      # Get standard rates for Sweden
      {:ok, rates} = ExVat.TEDB.get_rates("SE")

      # Get food rates for multiple countries
      {:ok, rates} = ExVat.TEDB.get_rates(["SE", "DE", "FR"], categories: ["FOODSTUFFS"])

      # Get rates using atom categories
      {:ok, rates} = ExVat.TEDB.get_rates("SE", categories: [:foodstuffs, :restaurant])

  Returns a list of `%ExVat.TEDB.Rate{}` structs.
  """
  @spec get_rates(String.t() | [String.t()], keyword()) :: {:ok, [Rate.t()]} | {:error, atom() | map()}
  def get_rates(countries, opts \\ [])

  def get_rates(country, opts) when is_binary(country) do
    get_rates([country], opts)
  end

  def get_rates(countries, opts) when is_list(countries) do
    categories = opts |> Keyword.get(:categories, []) |> normalize_categories()
    cn_codes = Keyword.get(opts, :cn_codes, [])
    cpa_codes = Keyword.get(opts, :cpa_codes, [])
    from_date = Keyword.get(opts, :from)
    to_date = Keyword.get(opts, :to, Date.utc_today())
    timeout = Keyword.get(opts, :timeout, 30_000)

    body = build_request_body(countries, categories, cn_codes, cpa_codes, from_date, to_date)

    case do_request(body, timeout) do
      {:ok, response_body} -> parse_response(response_body)
      {:error, _} = error -> error
    end
  end

  @doc """
  Gets the standard VAT rate for a country.

  ## Examples

      {:ok, 25.0} = ExVat.TEDB.standard_rate("SE")
      {:ok, 19.0} = ExVat.TEDB.standard_rate("DE")
  """
  @spec standard_rate(String.t(), keyword()) :: {:ok, number()} | {:error, term()}
  def standard_rate(country, opts \\ []) do
    case get_rates(country, opts) do
      {:ok, rates} ->
        standard = Enum.find(rates, fn r -> r.type == :standard end)

        if standard do
          {:ok, standard.rate}
        else
          {:error, :no_standard_rate}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the standard VAT rates for all EU countries.

  Returns a map of country code to rate.

  ## Examples

      {:ok, %{"SE" => 25.0, "DE" => 19.0, ...}} = ExVat.TEDB.standard_rates()
  """
  @spec standard_rates(keyword()) :: {:ok, %{String.t() => number()}} | {:error, term()}
  def standard_rates(opts \\ []) do
    countries = ExVat.country_codes()

    case get_rates(countries, opts) do
      {:ok, rates} ->
        rate_map =
          rates
          |> Enum.filter(fn r -> r.type == :standard end)
          |> Enum.map(fn r -> {r.country, r.rate} end)
          |> Enum.into(%{})

        {:ok, rate_map}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets rates for a specific category.

  Returns a list of `%ExVat.TEDB.Rate{}` structs for the given category.

  ## Examples

      {:ok, rates} = ExVat.TEDB.category_rates("SE", :foodstuffs)
      #=> {:ok, [%Rate{type: :reduced, rate: 12.0, category: "FOODSTUFFS"}, ...]}
  """
  @spec category_rates(String.t(), atom() | String.t(), keyword()) ::
          {:ok, [Rate.t()]} | {:error, atom() | map()}
  def category_rates(country, category, opts \\ []) do
    category_id =
      case category do
        cat when is_atom(cat) -> Map.get(@categories, cat, Atom.to_string(cat) |> String.upcase())
        cat when is_binary(cat) -> cat
      end

    get_rates(country, Keyword.put(opts, :categories, [category_id]))
  end

  # Build SOAP request body
  defp build_request_body(countries, categories, cn_codes, cpa_codes, from_date, to_date) do
    member_states =
      Enum.map_join(countries, "\n", fn code ->
        "<urn1:isoCode>#{String.upcase(code)}</urn1:isoCode>"
      end)

    date_elements = build_date_elements(from_date, to_date)
    category_elements = build_category_elements(categories)
    cn_elements = build_code_elements("cnCodes", cn_codes)
    cpa_elements = build_code_elements("cpaCodes", cpa_codes)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                      xmlns:urn="#{@namespace}"
                      xmlns:urn1="#{@types_namespace}">
      <soapenv:Header/>
      <soapenv:Body>
        <urn:retrieveVatRatesReqMsg>
          <urn1:memberStates>
            #{member_states}
          </urn1:memberStates>
          #{date_elements}
          #{category_elements}
          #{cn_elements}
          #{cpa_elements}
        </urn:retrieveVatRatesReqMsg>
      </soapenv:Body>
    </soapenv:Envelope>
    """
  end

  defp build_date_elements(nil, to_date) do
    # Use situationOn for single date query
    "<urn1:situationOn>#{Date.to_iso8601(to_date)}</urn1:situationOn>"
  end

  defp build_date_elements(from_date, to_date) do
    """
    <urn1:from>#{Date.to_iso8601(from_date)}</urn1:from>
    <urn1:to>#{Date.to_iso8601(to_date)}</urn1:to>
    """
  end

  defp build_category_elements([]), do: ""

  defp build_category_elements(categories) do
    identifiers = Enum.map_join(categories, "\n", fn cat ->
      "<urn1:identifier>#{cat}</urn1:identifier>"
    end)

    """
    <urn1:categories>
      #{identifiers}
    </urn1:categories>
    """
  end

  defp build_code_elements(_name, []), do: ""

  defp build_code_elements(name, codes) do
    values = Enum.map_join(codes, "\n", fn code ->
      "<urn1:value>#{code}</urn1:value>"
    end)

    """
    <urn1:#{name}>
      #{values}
    </urn1:#{name}>
    """
  end

  defp normalize_categories(categories) do
    Enum.map(categories, fn
      cat when is_atom(cat) -> Map.get(@categories, cat, Atom.to_string(cat) |> String.upcase())
      cat when is_binary(cat) -> cat
    end)
  end

  defp do_request(body, timeout) do
    http_client = Application.get_env(:ex_vat, :http_client, ExVat.HTTP)

    headers = [
      {"Content-Type", "text/xml; charset=utf-8"},
      {"SOAPAction", @soap_action}
    ]

    case http_client.post(@tedb_endpoint, body, headers, recv_timeout: timeout) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %{status_code: status, body: response_body}} ->
        Logger.warning("[ExVat.TEDB] HTTP #{status}: #{String.slice(response_body, 0, 200)}")
        {:error, parse_soap_fault(response_body)}

      {:error, %{reason: reason}} ->
        Logger.warning("[ExVat.TEDB] Request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_response(xml) do
    # Simple XML parsing - extract vatRateResults
    rates =
      xml
      |> extract_rate_results()
      |> Enum.map(&parse_rate_result/1)

    {:ok, rates}
  rescue
    e ->
      Logger.error("[ExVat.TEDB] Failed to parse response: #{inspect(e)}")
      {:error, :parse_error}
  end

  defp extract_rate_results(xml) do
    # Extract all <vatRateResults>...</vatRateResults> blocks
    ~r/<vatRateResults>(.*?)<\/vatRateResults>/s
    |> Regex.scan(xml, capture: :all_but_first)
    |> Enum.map(fn [content] -> content end)
  end

  defp parse_rate_result(xml) do
    category_id = extract_tag(xml, "identifier")
    category_desc = extract_tag(xml, "description")

    %Rate{
      country: extract_tag(xml, "memberState"),
      type: parse_rate_type(xml),
      rate: parse_rate_value(xml),
      category: category_id,
      category_description: category_desc,
      comment: extract_tag(xml, "comment"),
      valid_from: parse_date(extract_tag(xml, "situationOn"))
    }
  end

  @rate_type_mapping %{
    "STANDARD" => :standard,
    "REDUCED" => :reduced,
    "DEFAULT" => :standard,
    "REDUCED_RATE" => :reduced,
    "SUPER_REDUCED_RATE" => :super_reduced,
    "PARKING_RATE" => :parking,
    "NOT_APPLICABLE" => :not_applicable,
    "OUT_OF_SCOPE" => :out_of_scope,
    "EXEMPTED" => :exempt
  }

  defp parse_rate_type(xml) do
    type = extract_tag(xml, "type")
    Map.get(@rate_type_mapping, type, :unknown)
  end

  defp parse_rate_value(xml) do
    case extract_nested_tag(xml, "rate", "value") do
      nil -> nil
      value -> parse_number(value)
    end
  end

  defp extract_tag(xml, tag) do
    case Regex.run(~r/<#{tag}>(.*?)<\/#{tag}>/s, xml) do
      [_, value] -> String.trim(value)
      nil -> nil
    end
  end

  defp extract_nested_tag(xml, parent, child) do
    case Regex.run(~r/<#{parent}>(.*?)<\/#{parent}>/s, xml) do
      [_, parent_content] -> extract_tag(parent_content, child)
      nil -> nil
    end
  end

  defp parse_number(nil), do: nil

  defp parse_number(str) do
    case Float.parse(str) do
      {num, _} -> num
      :error -> nil
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_soap_fault(xml) do
    code = extract_tag(xml, "code") || extract_tag(xml, "faultCode")
    description = extract_tag(xml, "description") || extract_tag(xml, "faultString")

    %{
      code: code,
      description: description
    }
  end
end
