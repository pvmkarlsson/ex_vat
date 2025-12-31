defmodule ExVat.TARIC do
  @moduledoc """
  Client for the EU TARIC (Integrated Tariff) SOAP API.

  Retrieves CN (Combined Nomenclature) code descriptions and measures.
  Can be combined with TEDB to get VAT rates for specific goods.

  ## Endpoint

  `https://ec.europa.eu/taxation_customs/dds2/taric/services/goods`

  ## Features

  - CN code descriptions in any EU language
  - Trade measures per goods code and country
  - Historical data by reference date
  - Combined VAT rate lookup via `vat_rates/3`

  ## CN Codes

  CN codes are 8-10 digit codes used to classify goods for customs and VAT purposes.
  They follow a hierarchical structure:

  - 2 digits: Chapter (e.g., 01 = Live animals)
  - 4 digits: Heading (e.g., 0101 = Live horses)
  - 6 digits: Subheading (e.g., 010121 = Pure-bred breeding horses)
  - 8 digits: CN subheading (e.g., 01012100 = Pure-bred breeding horses)
  - 10 digits: TARIC subheading (full code)

  ## Usage

      # Get description of a CN code
      {:ok, goods} = ExVat.TARIC.describe("0101", "EN")
      goods.description  #=> "Live horses, asses, mules and hinnies"

      # Get VAT rates for goods in a country
      {:ok, goods} = ExVat.TARIC.vat_rates("9706", "DE")
      ExVat.TARIC.Goods.lowest_rate(goods)  #=> 7.0

  ## Error Handling

  Functions return `{:error, reason}` where reason can be:

    * `:no_description` - No description found for the CN code
    * `{:http_error, status}` - HTTP error with status code
    * Other atoms for network errors (`:timeout`, `:econnrefused`, etc.)

  ## Rate Limits

  Maximum 100 requests per second.
  """

  require Logger

  alias ExVat.TARIC.Goods

  @taric_endpoint "https://ec.europa.eu/taxation_customs/dds2/taric/services/goods"
  @namespace "http://goodsNomenclatureForWS.ws.taric.dds.s/"

  @type measure :: %{
          type: String.t(),
          description: String.t() | nil,
          duty_expression: String.t() | nil,
          additional_code: String.t() | nil
        }

  @type measures_result :: %{
          code: String.t(),
          country: String.t(),
          measures: [measure()]
        }

  @doc """
  Gets the description of a CN code.

  Returns an `%ExVat.TARIC.Goods{}` struct with the code description.

  ## Parameters

    * `code` - CN code (2-10 digits)
    * `language` - ISO language code (default: "EN")
    * `opts` - Options:
      * `:reference_date` - Date for historical lookup (default: today)
      * `:timeout` - Request timeout in ms (default: 30000)

  ## Examples

      {:ok, goods} = ExVat.TARIC.describe("0101", "EN")
      #=> {:ok, %ExVat.TARIC.Goods{
      #=>   cn_code: "0101000000",
      #=>   cn_code_formatted: "0101 00 00 00",
      #=>   description: "Live horses, asses, mules and hinnies",
      #=>   language: "EN"
      #=> }}

      {:ok, goods} = ExVat.TARIC.describe("9706000000", "DE")
      #=> {:ok, %ExVat.TARIC.Goods{
      #=>   cn_code: "9706000000",
      #=>   cn_code_formatted: "9706 00 00 00",
      #=>   description: "Antiquitäten...",
      #=>   language: "DE"
      #=> }}
  """
  @spec describe(String.t(), String.t(), keyword()) ::
          {:ok, Goods.t()} | {:error, term()}
  def describe(code, language \\ "EN", opts \\ []) do
    reference_date = Keyword.get(opts, :reference_date)
    timeout = Keyword.get(opts, :timeout, 30_000)

    body = build_description_request(code, language, reference_date)

    case do_request(body, timeout) do
      {:ok, response_body} -> parse_description_response(response_body, code, language)
      {:error, _} = error -> error
    end
  end

  @doc """
  Gets trade measures for a CN code and country.

  ## Parameters

    * `code` - CN code (8-10 digits recommended)
    * `country` - ISO country code
    * `opts` - Options:
      * `:reference_date` - Date for historical lookup (default: today)
      * `:trade_movement` - "I" for import, "E" for export (default: both)
      * `:timeout` - Request timeout in ms (default: 30000)

  ## Examples

      {:ok, result} = ExVat.TARIC.measures("01012100", "SE")
      #=> %{code: "01012100", country: "SE", measures: [...]}
  """
  @spec measures(String.t(), String.t(), keyword()) ::
          {:ok, measures_result()} | {:error, term()}
  def measures(code, country, opts \\ []) do
    reference_date = Keyword.get(opts, :reference_date)
    trade_movement = Keyword.get(opts, :trade_movement)
    timeout = Keyword.get(opts, :timeout, 30_000)

    body = build_measures_request(code, country, reference_date, trade_movement)

    case do_request(body, timeout) do
      {:ok, response_body} -> parse_measures_response(response_body, code, country)
      {:error, _} = error -> error
    end
  end

  @doc """
  Gets VAT rates for a CN code in a country.

  Combines TARIC description with TEDB VAT rates. Returns a `%ExVat.TARIC.Goods{}`
  struct populated with description, country, and applicable VAT rates.

  ## Parameters

    * `cn_code` - CN code (2-10 digits)
    * `country` - ISO country code for VAT rates
    * `opts` - Options:
      * `:language` - Language for description (default: "EN")
      * `:reference_date` - Date for historical lookup
      * `:timeout` - Request timeout in ms (default: 30000)

  ## Examples

      {:ok, goods} = ExVat.TARIC.vat_rates("9706", "DE")
      #=> {:ok, %ExVat.TARIC.Goods{
      #=>   cn_code: "9706000000",
      #=>   cn_code_formatted: "9706 00 00 00",
      #=>   description: "Antiques of an age exceeding 100 years",
      #=>   language: "EN",
      #=>   country: "DE",
      #=>   rates: [%ExVat.TEDB.Rate{type: :reduced, rate: 7.0, ...}, ...]
      #=> }}

      # Check if reduced rate applies
      ExVat.TARIC.Goods.has_reduced_rate?(goods)
      #=> true

      # Get the lowest applicable rate
      ExVat.TARIC.Goods.lowest_rate(goods)
      #=> 7.0
  """
  @spec vat_rates(String.t(), String.t(), keyword()) ::
          {:ok, Goods.t()} | {:error, term()}
  def vat_rates(cn_code, country, opts \\ []) do
    language = Keyword.get(opts, :language, "EN")

    with {:ok, %Goods{} = goods} <- describe(cn_code, language, opts),
         {:ok, rates} <- ExVat.TEDB.get_rates(country, Keyword.put(opts, :cn_codes, [cn_code])) do
      {:ok, %Goods{goods | country: String.upcase(country), rates: rates}}
    end
  end

  @doc """
  Validates a CN code format.

  CN codes should be 2-10 digits, with 8 or 10 being most specific.

  ## Examples

      ExVat.TARIC.valid_cn_code?("0101")
      #=> true

      ExVat.TARIC.valid_cn_code?("01012100")
      #=> true

      ExVat.TARIC.valid_cn_code?("abc")
      #=> false
  """
  @spec valid_cn_code?(String.t()) :: boolean()
  def valid_cn_code?(code) when is_binary(code) do
    normalized = String.replace(code, ~r/[\s\.]/, "")
    Regex.match?(~r/^\d{2,10}$/, normalized)
  end

  def valid_cn_code?(_), do: false

  @doc """
  Normalizes a CN code by removing spaces and dots, and padding to 10 digits.

  The TARIC API requires exactly 10 digits.

  ## Examples

      ExVat.TARIC.normalize_cn_code("0101 29 10")
      #=> "0101291000"

      ExVat.TARIC.normalize_cn_code("9706.00.00")
      #=> "9706000000"

      ExVat.TARIC.normalize_cn_code("01")
      #=> "0100000000"
  """
  @spec normalize_cn_code(String.t()) :: String.t()
  def normalize_cn_code(code) when is_binary(code) do
    code
    |> String.replace(~r/[\s\.]/, "")
    |> String.pad_trailing(10, "0")
  end

  # Build SOAP request for description
  defp build_description_request(code, language, reference_date) do
    date_element =
      if reference_date do
        "<tns:referenceDate>#{Date.to_iso8601(reference_date)}</tns:referenceDate>"
      else
        ""
      end

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                      xmlns:tns="#{@namespace}">
      <soapenv:Header/>
      <soapenv:Body>
        <tns:goodsDescrForWs>
          <tns:goodsCode>#{normalize_cn_code(code)}</tns:goodsCode>
          <tns:languageCode>#{String.downcase(language)}</tns:languageCode>
          #{date_element}
        </tns:goodsDescrForWs>
      </soapenv:Body>
    </soapenv:Envelope>
    """
  end

  # Build SOAP request for measures
  defp build_measures_request(code, country, reference_date, trade_movement) do
    date_element =
      if reference_date do
        "<tns:referenceDate>#{Date.to_iso8601(reference_date)}</tns:referenceDate>"
      else
        ""
      end

    trade_element =
      if trade_movement do
        "<tns:tradeMovement>#{trade_movement}</tns:tradeMovement>"
      else
        ""
      end

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                      xmlns:tns="#{@namespace}">
      <soapenv:Header/>
      <soapenv:Body>
        <tns:goodsMeasForWs>
          <tns:goodsCode>#{normalize_cn_code(code)}</tns:goodsCode>
          <tns:countryCode>#{String.upcase(country)}</tns:countryCode>
          #{date_element}
          #{trade_element}
        </tns:goodsMeasForWs>
      </soapenv:Body>
    </soapenv:Envelope>
    """
  end

  defp do_request(body, timeout) do
    http_client = Application.get_env(:ex_vat, :http_client, ExVat.HTTP)

    headers = [
      {"Content-Type", "text/xml; charset=utf-8"}
    ]

    case http_client.post(@taric_endpoint, body, headers, recv_timeout: timeout) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %{status_code: status, body: response_body}} ->
        Logger.warning("[ExVat.TARIC] HTTP #{status}: #{String.slice(response_body, 0, 200)}")
        {:error, {:http_error, status}}

      {:error, %{reason: reason}} ->
        Logger.warning("[ExVat.TARIC] Request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_description_response(xml, code, language) do
    # Extract description from response
    description = extract_tag(xml, "goodsDescription") || extract_tag(xml, "description")

    if description do
      normalized_code = normalize_cn_code(code)

      {:ok,
       %Goods{
         cn_code: normalized_code,
         cn_code_formatted: Goods.format_cn_code(normalized_code),
         description: description,
         language: String.upcase(language)
       }}
    else
      {:error, :no_description}
    end
  end

  defp parse_measures_response(xml, code, country) do
    # Extract measures from response
    # This is a simplified parser - the actual response structure may be more complex
    measures =
      ~r/<measure>(.*?)<\/measure>/s
      |> Regex.scan(xml, capture: :all_but_first)
      |> Enum.map(fn [content] ->
        %{
          type: extract_tag(content, "measureType") || extract_tag(content, "type"),
          description: extract_tag(content, "description"),
          duty_expression: extract_tag(content, "dutyExpression"),
          additional_code: extract_tag(content, "additionalCode")
        }
      end)

    {:ok,
     %{
       code: normalize_cn_code(code),
       country: String.upcase(country),
       measures: measures
     }}
  end

  defp extract_tag(xml, tag) do
    case Regex.run(~r/<#{tag}[^>]*>(.*?)<\/#{tag}>/s, xml) do
      [_, value] -> String.trim(value)
      nil -> nil
    end
  end
end
