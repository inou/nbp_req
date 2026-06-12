defmodule NbpReq.Client do
  @moduledoc false
  # Thin wrapper around Req that talks to https://api.nbp.pl/api.

  @base_url "https://api.nbp.pl/api"

  @doc """
  Performs a GET request against the NBP API and normalizes the response.

  Extra Req options can be injected globally via the `:req_options`
  application env key (used by tests to plug `Req.Test`) or per call via
  `opts[:req_options]`.
  """
  @spec get(String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def get(path, opts \\ []) do
    request =
      [base_url: @base_url, url: path, params: [format: "json"]]
      |> Req.new()
      |> Req.merge(Application.get_env(:nbp_req, :req_options, []))
      |> Req.merge(Keyword.get(opts, :req_options, []))

    case Req.get(request) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: 404}} -> {:error, :not_found}
      {:ok, %Req.Response{status: 400, body: body}} -> {:error, {:bad_request, body}}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Builds the path suffix selecting which data points to fetch.

  Exactly one of the following may be used:

    * no option - the current value
    * `today: true` - today's value (404 if not published yet)
    * `date: %Date{}` - the value for a given day
    * `last: n` - the last `n` values
    * `from: %Date{}, to: %Date{}` - an inclusive date range
  """
  @spec path_suffix(keyword()) :: String.t()
  def path_suffix(opts) do
    selectors = Keyword.take(opts, [:today, :date, :last, :from, :to])

    case Enum.sort(Keyword.keys(selectors)) do
      [] ->
        ""

      [:today] ->
        if Keyword.fetch!(selectors, :today), do: "/today", else: ""

      [:date] ->
        "/" <> Date.to_iso8601(date!(selectors, :date))

      [:last] ->
        last = Keyword.fetch!(selectors, :last)

        unless is_integer(last) and last > 0 do
          raise ArgumentError, ":last must be a positive integer, got: #{inspect(last)}"
        end

        "/last/#{last}"

      [:from, :to] ->
        "/#{Date.to_iso8601(date!(selectors, :from))}/#{Date.to_iso8601(date!(selectors, :to))}"

      [single] when single in [:from, :to] ->
        raise ArgumentError, "both :from and :to must be given for a date range"

      keys ->
        raise ArgumentError,
              "options #{inspect(keys)} conflict; use only one of " <>
                ":today, :date, :last or :from/:to"
    end
  end

  defp date!(selectors, key) do
    case Keyword.fetch!(selectors, key) do
      %Date{} = date -> date
      other -> raise ArgumentError, "#{inspect(key)} must be a Date, got: #{inspect(other)}"
    end
  end
end
