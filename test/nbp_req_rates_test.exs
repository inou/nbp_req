defmodule NbpReqRatesTest do
  use ExUnit.Case, async: true

  describe "rates/3" do
    test "returns the current rate for a currency" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/rates/a/usd"
        assert conn.params["format"] == "json"

        Req.Test.json(conn, %{
          "table" => "A",
          "currency" => "dolar amerykański",
          "code" => "USD",
          "rates" => [
            %{"no" => "112/A/NBP/2026", "effectiveDate" => "2026-06-12", "mid" => 3.99}
          ]
        })
      end)

      assert {:ok, %NbpReq.CurrencyRates{} = currency} = NbpReq.rates(:a, "USD")
      assert currency.table == "A"
      assert currency.currency == "dolar amerykański"
      assert currency.code == "USD"

      assert [%NbpReq.Rate{no: "112/A/NBP/2026", effective_date: ~D[2026-06-12], mid: 3.99}] =
               currency.rates
    end

    test "fetches the last n rates from table C with bid/ask" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/rates/c/eur/last/2"

        Req.Test.json(conn, %{
          "table" => "C",
          "currency" => "euro",
          "code" => "EUR",
          "rates" => [
            %{
              "no" => "111/C/NBP/2026",
              "tradingDate" => "2026-06-10",
              "effectiveDate" => "2026-06-11",
              "bid" => 4.55,
              "ask" => 4.64
            },
            %{
              "no" => "112/C/NBP/2026",
              "tradingDate" => "2026-06-11",
              "effectiveDate" => "2026-06-12",
              "bid" => 4.56,
              "ask" => 4.65
            }
          ]
        })
      end)

      assert {:ok, %NbpReq.CurrencyRates{rates: [first, _second]}} =
               NbpReq.rates(:c, "EUR", last: 2)

      assert first.trading_date == ~D[2026-06-10]
      assert first.bid == 4.55
      assert first.ask == 4.64
      assert first.mid == nil
    end

    test "fetches a rate for a date range" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/rates/a/chf/2026-06-01/2026-06-10"

        Req.Test.json(conn, %{
          "table" => "A",
          "currency" => "frank szwajcarski",
          "code" => "CHF",
          "rates" => [%{"no" => "105/A/NBP/2026", "effectiveDate" => "2026-06-01", "mid" => 4.51}]
        })
      end)

      assert {:ok, %NbpReq.CurrencyRates{}} =
               NbpReq.rates(:a, "CHF", from: ~D[2026-06-01], to: ~D[2026-06-10])
    end

    test "downcases the currency code in the path" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/rates/a/gbp"

        Req.Test.json(conn, %{
          "table" => "A",
          "currency" => "funt szterling",
          "code" => "GBP",
          "rates" => [%{"no" => "112/A/NBP/2026", "effectiveDate" => "2026-06-12", "mid" => 5.12}]
        })
      end)

      assert {:ok, _} = NbpReq.rates(:a, "gbp")
    end

    test "returns :not_found when the currency does not exist" do
      Req.Test.stub(NbpReq, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(404, "404 NotFound - Not Found - Brak danych")
      end)

      assert {:error, :not_found} = NbpReq.rates(:a, "XXX")
    end

    test "rejects an invalid currency code" do
      assert_raise ArgumentError, fn -> NbpReq.rates(:a, "US") end
      assert_raise ArgumentError, fn -> NbpReq.rates(:a, :usd) end
    end
  end
end
