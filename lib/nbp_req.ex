defmodule NbpReq do
  @moduledoc """
  HTTP client for the [NBP Web API](https://api.nbp.pl/) built on `Req`.

  Provides access to exchange rate tables, single currency rates and gold
  prices published by Narodowy Bank Polski.

  All functions accept the same query options (at most one of):

    * `today: true` - today's data (the API returns 404 if not published yet)
    * `date: %Date{}` - data for a specific day
    * `last: n` - the last `n` data points
    * `from: %Date{}, to: %Date{}` - an inclusive date range (max 367 days)

  With no query option, the most recent data is returned.

  ## Examples

      NbpReq.tables(:a)
      NbpReq.rates(:a, "USD", last: 10)
      NbpReq.gold_prices(from: ~D[2026-01-01], to: ~D[2026-01-31])

  ## Errors

  Functions return `{:error, reason}` where reason is:

    * `:not_found` - no data for the requested day/range (HTTP 404)
    * `{:bad_request, message}` - invalid query, e.g. range over 367 days (HTTP 400)
    * `{:http_error, status, body}` - any other unexpected HTTP status
    * an exception struct (e.g. `Req.TransportError`) for connection errors
  """

  alias NbpReq.{Client, CurrencyRates, GoldPrice, Table}

  @tables [:a, :b, :c]

  @typedoc "Exchange rate table identifier."
  @type table :: :a | :b | :c

  @typedoc "Query options shared by all endpoints."
  @type query_opts :: [
          today: boolean(),
          date: Date.t(),
          last: pos_integer(),
          from: Date.t(),
          to: Date.t(),
          req_options: keyword()
        ]

  @doc """
  Fetches complete exchange rate tables.

  Returns a list of `NbpReq.Table` structs (the API always wraps tables in
  a list, even for a single day).

  ## Examples

      {:ok, [table]} = NbpReq.tables(:a)
      {:ok, tables} = NbpReq.tables(:a, last: 5)

  """
  @spec tables(table(), query_opts()) :: {:ok, [Table.t()]} | {:error, term()}
  def tables(table \\ :a, opts \\ []) do
    path = "/exchangerates/tables/#{table_segment!(table)}" <> Client.path_suffix(opts)

    with {:ok, body} <- Client.get(path, opts) do
      {:ok, Enum.map(body, &Table.from_json/1)}
    end
  end

  @doc """
  Fetches exchange rates for a single currency.

  `code` is a three-letter ISO 4217 currency code (case insensitive).
  Returns a `NbpReq.CurrencyRates` struct with one `NbpReq.Rate` per
  quoted day.

  ## Examples

      {:ok, currency} = NbpReq.rates(:a, "USD")
      {:ok, currency} = NbpReq.rates(:c, "EUR", last: 10)

  """
  @spec rates(table(), String.t(), query_opts()) ::
          {:ok, CurrencyRates.t()} | {:error, term()}
  def rates(table, code, opts \\ []) do
    path =
      "/exchangerates/rates/#{table_segment!(table)}/#{code_segment!(code)}" <>
        Client.path_suffix(opts)

    with {:ok, body} <- Client.get(path, opts) do
      {:ok, CurrencyRates.from_json(body)}
    end
  end

  @doc """
  Fetches gold prices (1g of 1000 fineness gold, in PLN).

  Returns a list of `NbpReq.GoldPrice` structs.

  ## Examples

      {:ok, [price]} = NbpReq.gold_prices()
      {:ok, prices} = NbpReq.gold_prices(last: 30)

  """
  @spec gold_prices(query_opts()) :: {:ok, [GoldPrice.t()]} | {:error, term()}
  def gold_prices(opts \\ []) do
    path = "/cenyzlota" <> Client.path_suffix(opts)

    with {:ok, body} <- Client.get(path, opts) do
      {:ok, Enum.map(body, &GoldPrice.from_json/1)}
    end
  end

  defp code_segment!(code) when is_binary(code) do
    downcased = String.downcase(code)

    unless downcased =~ ~r/^[a-z]{3}$/ do
      raise ArgumentError,
            "currency code must be a three-letter ISO 4217 code, got: #{inspect(code)}"
    end

    downcased
  end

  defp code_segment!(other) do
    raise ArgumentError,
          "currency code must be a three-letter ISO 4217 code, got: #{inspect(other)}"
  end

  defp table_segment!(table) when table in @tables, do: Atom.to_string(table)

  defp table_segment!(other) do
    raise ArgumentError, "table must be one of #{inspect(@tables)}, got: #{inspect(other)}"
  end
end
