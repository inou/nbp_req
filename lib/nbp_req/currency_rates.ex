defmodule NbpReq.CurrencyRates do
  @moduledoc """
  A time series of exchange rates for a single currency.

  Wraps the response of the `/exchangerates/rates/{table}/{code}` endpoint:
  the currency metadata plus one `NbpReq.Rate` per quoted day.
  """

  alias NbpReq.Rate

  defstruct [:table, :currency, :code, rates: []]

  @type t :: %__MODULE__{
          table: String.t(),
          currency: String.t(),
          code: String.t(),
          rates: [Rate.t()]
        }

  @doc false
  @spec from_json(map()) :: t()
  def from_json(map) when is_map(map) do
    %__MODULE__{
      table: map["table"],
      currency: map["currency"],
      code: map["code"],
      rates: Enum.map(map["rates"] || [], &Rate.from_json/1)
    }
  end
end
