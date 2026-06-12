# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`nbp_req` is an Elixir HTTP client library for the NBP Web API (https://api.nbp.pl/ — Polish National Bank exchange rates and gold prices), built on `Req`. Plain Mix library, no OTP application/supervision tree.

## Commands

- `mix test` — run the test suite (no network needed; HTTP is stubbed)
- `mix test test/nbp_req_rates_test.exs` — run one file; append `:LINE` for one test
- `mix format` — format; `mix format --check-formatted` to verify

## Architecture

Public API lives entirely in `NbpReq` (`lib/nbp_req.ex`): `tables/2`, `rates/3`, `gold_prices/1`. Each builds a URL path and delegates to `NbpReq.Client`.

- `NbpReq.Client` (`lib/nbp_req/client.ex`) — private HTTP layer. `get/2` normalizes responses into `{:ok, body}` / `{:error, :not_found | {:bad_request, msg} | {:http_error, status, body} | exception}`. `path_suffix/1` translates the shared query options (`:today`, `:date`, `:last`, `:from`/`:to` — mutually exclusive, validated with `ArgumentError`) into URL suffixes used by every endpoint.
- Structs (`NbpReq.Table`, `NbpReq.CurrencyRates`, `NbpReq.Rate`, `NbpReq.GoldPrice`) each expose `from_json/1` parsing the API's JSON (Polish keys for gold: `data`/`cena`; camelCase elsewhere). `NbpReq.Rate` is shared between table rows and currency time series — unused fields stay `nil` (tables A/B have `:mid`; table C has `:bid`/`:ask` and `:trading_date`).

Req options are injected via `Application.get_env(:nbp_req, :req_options)` merged with per-call `opts[:req_options]`. Tests rely on this: `test/test_helper.exs` sets `plug: {Req.Test, NbpReq}`, and each test stubs with `Req.Test.stub(NbpReq, fun)` (async-safe). Tests that exercise 5xx/transport errors must pass `req_options: [retry: false]` to avoid Req's retry delays.

## Conventions

- TDD: write a failing test first, then implement (see test files for the stub pattern).
- New endpoints should reuse `Client.path_suffix/1` and the error contract rather than inventing new option shapes.
