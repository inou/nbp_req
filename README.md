# NbpReq

Elixir HTTP client for the [NBP Web API](https://api.nbp.pl/) (Narodowy Bank
Polski), built on [Req](https://hexdocs.pm/req). Provides exchange rate
tables, single currency rates, and gold prices.

## Usage

```elixir
# Current exchange rate table (A, B or C)
{:ok, [table]} = NbpReq.tables(:a)
table.effective_date #=> ~D[2026-06-12]
table.rates          #=> [%NbpReq.Rate{code: "USD", mid: 3.6767, ...}, ...]

# Rates for a single currency
{:ok, currency} = NbpReq.rates(:a, "USD")
{:ok, currency} = NbpReq.rates(:c, "EUR", last: 10)

# Gold prices (1g, 1000 fineness, PLN)
{:ok, prices} = NbpReq.gold_prices(from: ~D[2026-01-01], to: ~D[2026-01-31])
```

All functions accept the same query options (at most one of):

| Option | Meaning |
|---|---|
| _none_ | most recent data |
| `today: true` | today's data (404 before publication) |
| `date: %Date{}` | data for a specific day |
| `last: n` | last `n` data points |
| `from:`/`to:` | inclusive date range (API limit: 367 days) |

Errors come back as `{:error, :not_found}`, `{:error, {:bad_request, msg}}`,
`{:error, {:http_error, status, body}}`, or `{:error, exception}` for
transport failures.

Extra Req options (e.g. `retry: false`) can be passed per call via
`req_options: [...]`, or globally via application config:

```elixir
config :nbp_req, req_options: [retry: false]
```

## Installation

Add `nbp_req` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nbp_req, "~> 0.1.0"}
  ]
end
```

## Testing

The test suite stubs HTTP with [`Req.Test`](https://hexdocs.pm/req/Req.Test.html)
— no network access needed:

```sh
mix test
```
