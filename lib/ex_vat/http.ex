defmodule ExVat.HTTP do
  @moduledoc """
  HTTP client wrapper using Req.

  Provides a consistent interface for HTTP requests that matches the
  expected API shape used throughout ExVat. Uses Req internally.

  ## Configuration

  You can provide a custom HTTP client by setting:

      config :ex_vat, :http_client, MyCustomClient

  Your client must implement the `ExVat.HTTP` behaviour:

      @behaviour ExVat.HTTP

      @impl true
      def post(url, body, headers, opts), do: ...

      @impl true
      def get(url, headers, opts), do: ...
  """

  @type response :: %{status_code: integer(), body: binary()}
  @type error :: %{reason: atom() | String.t()}

  @callback post(String.t(), String.t(), [{String.t(), String.t()}], keyword()) ::
              {:ok, response()} | {:error, error()}

  @callback get(String.t(), [{String.t(), String.t()}], keyword()) ::
              {:ok, response()} | {:error, error()}

  @behaviour __MODULE__

  @doc """
  Performs an HTTP POST request.

  ## Parameters

    * `url` - The URL to POST to
    * `body` - The request body (string)
    * `headers` - List of `{header_name, header_value}` tuples
    * `opts` - Options:
      * `:timeout` - Connect timeout in ms (default: 30000)
      * `:recv_timeout` - Receive timeout in ms (default: 15000)

  ## Returns

    * `{:ok, %{status_code: integer(), body: binary()}}` on success
    * `{:error, %{reason: atom()}}` on failure
  """
  @impl true
  @spec post(String.t(), String.t(), [{String.t(), String.t()}], keyword()) ::
          {:ok, response()} | {:error, error()}
  def post(url, body, headers, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    recv_timeout = Keyword.get(opts, :recv_timeout, 15_000)

    req_opts = [
      body: body,
      headers: headers,
      connect_options: [timeout: timeout],
      receive_timeout: recv_timeout,
      retry: false,
      decode_body: false
    ]

    case Req.post(url, req_opts) do
      {:ok, %Req.Response{status: status, body: response_body}} ->
        {:ok, %{status_code: status, body: response_body}}

      {:error, exception} ->
        {:error, %{reason: normalize_error(exception)}}
    end
  end

  @doc """
  Performs an HTTP GET request.

  ## Parameters

    * `url` - The URL to GET
    * `headers` - List of `{header_name, header_value}` tuples
    * `opts` - Options:
      * `:timeout` - Connect timeout in ms (default: 30000)
      * `:recv_timeout` - Receive timeout in ms (default: 15000)

  ## Returns

    * `{:ok, %{status_code: integer(), body: binary()}}` on success
    * `{:error, %{reason: atom()}}` on failure
  """
  @impl true
  @spec get(String.t(), [{String.t(), String.t()}], keyword()) ::
          {:ok, response()} | {:error, error()}
  def get(url, headers, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    recv_timeout = Keyword.get(opts, :recv_timeout, 15_000)

    req_opts = [
      headers: headers,
      connect_options: [timeout: timeout],
      receive_timeout: recv_timeout,
      retry: false,
      decode_body: false
    ]

    case Req.get(url, req_opts) do
      {:ok, %Req.Response{status: status, body: response_body}} ->
        {:ok, %{status_code: status, body: response_body}}

      {:error, exception} ->
        {:error, %{reason: normalize_error(exception)}}
    end
  end

  defp normalize_error(%Req.TransportError{reason: :timeout}), do: :timeout
  defp normalize_error(%Req.TransportError{reason: :econnrefused}), do: :econnrefused
  defp normalize_error(%Req.TransportError{reason: :closed}), do: :closed
  defp normalize_error(%Req.TransportError{reason: :ehostunreach}), do: :ehostunreach
  defp normalize_error(%Req.TransportError{reason: :enetunreach}), do: :enetunreach
  defp normalize_error(%Req.TransportError{reason: reason}), do: reason
  defp normalize_error(%{reason: reason}), do: reason
  defp normalize_error(exception) when is_exception(exception), do: Exception.message(exception)
  defp normalize_error(other), do: other
end
