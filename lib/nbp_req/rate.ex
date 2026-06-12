defmodule NbpReq.Rate do
  @moduledoc """
  A single exchange rate entry.

  Rates coming from tables A and B carry a `:mid` (average) value, while
  table C rates carry `:bid`/`:ask` values. Fields that are absent in the
  API response are `nil`.

  When the rate is part of a currency time series (`NbpReq.rates/3`), the
  `:no` (table number) and `:effective_date` fields are set instead of
  `:currency`/`:code`, which then live on the parent `NbpReq.CurrencyRates`.
  """

  defstruct [:currency, :code, :no, :effective_date, :trading_date, :mid, :bid, :ask]

  @type t :: %__MODULE__{
          currency: String.t() | nil,
          code: String.t() | nil,
          no: String.t() | nil,
          effective_date: Date.t() | nil,
          trading_date: Date.t() | nil,
          mid: number() | nil,
          bid: number() | nil,
          ask: number() | nil
        }

  @doc false
  @spec from_json(map()) :: t()
  def from_json(map) when is_map(map) do
    %__MODULE__{
      currency: map["currency"],
      code: map["code"],
      no: map["no"],
      effective_date: parse_date(map["effectiveDate"]),
      trading_date: parse_date(map["tradingDate"]),
      mid: map["mid"],
      bid: map["bid"],
      ask: map["ask"]
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(iso8601), do: Date.from_iso8601!(iso8601)
end
