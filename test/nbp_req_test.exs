defmodule NbpReqTest do
  use ExUnit.Case, async: true

  describe "tables/2" do
    test "returns the current table A parsed into structs" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/a"
        assert conn.params["format"] == "json"

        Req.Test.json(conn, [
          %{
            "table" => "A",
            "no" => "112/A/NBP/2026",
            "effectiveDate" => "2026-06-12",
            "rates" => [
              %{"currency" => "dolar amerykański", "code" => "USD", "mid" => 3.99},
              %{"currency" => "euro", "code" => "EUR", "mid" => 4.61}
            ]
          }
        ])
      end)

      assert {:ok, [%NbpReq.Table{} = table]} = NbpReq.tables(:a)
      assert table.table == "A"
      assert table.no == "112/A/NBP/2026"
      assert table.effective_date == ~D[2026-06-12]

      assert [
               %NbpReq.Rate{currency: "dolar amerykański", code: "USD", mid: 3.99},
               %NbpReq.Rate{currency: "euro", code: "EUR", mid: 4.61}
             ] = table.rates
    end

    test "parses table C with trading date and bid/ask rates" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/c"

        Req.Test.json(conn, [
          %{
            "table" => "C",
            "no" => "112/C/NBP/2026",
            "tradingDate" => "2026-06-11",
            "effectiveDate" => "2026-06-12",
            "rates" => [
              %{"currency" => "dolar amerykański", "code" => "USD", "bid" => 3.95, "ask" => 4.03}
            ]
          }
        ])
      end)

      assert {:ok, [table]} = NbpReq.tables(:c)
      assert table.trading_date == ~D[2026-06-11]
      assert [%NbpReq.Rate{code: "USD", bid: 3.95, ask: 4.03, mid: nil}] = table.rates
    end

    test "fetches today's table" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/a/today"
        Req.Test.json(conn, [table_a_json()])
      end)

      assert {:ok, [%NbpReq.Table{}]} = NbpReq.tables(:a, today: true)
    end

    test "fetches the last n tables" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/a/last/3"
        Req.Test.json(conn, [table_a_json(), table_a_json(), table_a_json()])
      end)

      assert {:ok, tables} = NbpReq.tables(:a, last: 3)
      assert length(tables) == 3
    end

    test "fetches a table for a specific date" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/a/2026-06-10"
        Req.Test.json(conn, [table_a_json()])
      end)

      assert {:ok, [%NbpReq.Table{}]} = NbpReq.tables(:a, date: ~D[2026-06-10])
    end

    test "fetches tables for a date range" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/exchangerates/tables/b/2026-06-01/2026-06-10"
        Req.Test.json(conn, [table_a_json()])
      end)

      assert {:ok, [%NbpReq.Table{}]} =
               NbpReq.tables(:b, from: ~D[2026-06-01], to: ~D[2026-06-10])
    end

    test "rejects an invalid table name" do
      assert_raise ArgumentError, fn -> NbpReq.tables(:x) end
    end

    test "rejects conflicting query options" do
      assert_raise ArgumentError, fn -> NbpReq.tables(:a, last: 3, date: ~D[2026-06-10]) end
    end

    test "rejects :from without :to" do
      assert_raise ArgumentError, fn -> NbpReq.tables(:a, from: ~D[2026-06-01]) end
    end
  end

  defp table_a_json do
    %{
      "table" => "A",
      "no" => "112/A/NBP/2026",
      "effectiveDate" => "2026-06-12",
      "rates" => [%{"currency" => "dolar amerykański", "code" => "USD", "mid" => 3.99}]
    }
  end
end
