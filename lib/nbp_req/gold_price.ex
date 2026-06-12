defmodule NbpReq.GoldPrice do
  @moduledoc """
  The price of 1g of gold (1000 fineness) calculated by NBP for a given day.
  """

  defstruct [:date, :price]

  @type t :: %__MODULE__{date: Date.t(), price: number()}

  @doc false
  @spec from_json(map()) :: t()
  def from_json(%{"data" => date, "cena" => price}) do
    %__MODULE__{date: Date.from_iso8601!(date), price: price}
  end
end
