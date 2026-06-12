defmodule NbpReqGoldTest do
  use ExUnit.Case, async: true

  describe "gold_prices/1" do
    test "returns the current gold price" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/cenyzlota"
        assert conn.params["format"] == "json"

        Req.Test.json(conn, [%{"data" => "2026-06-12", "cena" => 253.41}])
      end)

      assert {:ok, [%NbpReq.GoldPrice{date: ~D[2026-06-12], price: 253.41}]} =
               NbpReq.gold_prices()
    end

    test "fetches the last n gold prices" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/cenyzlota/last/2"

        Req.Test.json(conn, [
          %{"data" => "2026-06-11", "cena" => 252.10},
          %{"data" => "2026-06-12", "cena" => 253.41}
        ])
      end)

      assert {:ok, [first, second]} = NbpReq.gold_prices(last: 2)
      assert first.date == ~D[2026-06-11]
      assert second.price == 253.41
    end

    test "fetches gold prices for a date range" do
      Req.Test.stub(NbpReq, fn conn ->
        assert conn.request_path == "/api/cenyzlota/2026-06-01/2026-06-10"
        Req.Test.json(conn, [%{"data" => "2026-06-01", "cena" => 250.0}])
      end)

      assert {:ok, [%NbpReq.GoldPrice{}]} =
               NbpReq.gold_prices(from: ~D[2026-06-01], to: ~D[2026-06-10])
    end
  end

  describe "error handling" do
    test "returns {:bad_request, message} on HTTP 400" do
      Req.Test.stub(NbpReq, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(
          400,
          "400 BadRequest - Przekroczony limit 367 dni / Limit of 367 days has been exceeded"
        )
      end)

      assert {:error, {:bad_request, message}} =
               NbpReq.gold_prices(from: ~D[2020-01-01], to: ~D[2026-01-01])

      assert message =~ "367"
    end

    test "returns {:http_error, status, body} on other statuses" do
      Req.Test.stub(NbpReq, fn conn ->
        Plug.Conn.send_resp(conn, 503, "Service Unavailable")
      end)

      assert {:error, {:http_error, 503, "Service Unavailable"}} =
               NbpReq.gold_prices(req_options: [retry: false])
    end

    test "returns the exception on transport errors" do
      Req.Test.stub(NbpReq, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Req.TransportError{reason: :econnrefused}} =
               NbpReq.gold_prices(req_options: [retry: false])
    end
  end
end
