defmodule NbpReq.Table do
  @moduledoc """
  A full exchange rate table (A, B or C) published by NBP.

  `:trading_date` is only present for table C; tables A and B carry just
  the `:effective_date`.
  """

  alias NbpReq.Rate

  defstruct [:table, :no, :effective_date, :trading_date, rates: []]

  @type t :: %__MODULE__{
          table: String.t(),
          no: String.t(),
          effective_date: Date.t(),
          trading_date: Date.t() | nil,
          rates: [Rate.t()]
        }

  @doc false
  @spec from_json(map()) :: t()
  def from_json(map) when is_map(map) do
    %__MODULE__{
      table: map["table"],
      no: map["no"],
      effective_date: parse_date(map["effectiveDate"]),
      trading_date: parse_date(map["tradingDate"]),
      rates: Enum.map(map["rates"] || [], &Rate.from_json/1)
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(iso8601), do: Date.from_iso8601!(iso8601)
end
