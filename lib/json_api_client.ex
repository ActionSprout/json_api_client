defmodule JsonApiClient do
  @moduledoc """
  A client library for interacting with REST APIs that comply with
  the JSON API spec described at http://jsonapi.org
  """

  @client_name Application.get_env(:json_api_client, :client_name)
  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]

  alias __MODULE__.Request

  @doc "Execute a JSON API Request using HTTP GET"
  def fetch(req), do: req |> Request.method(:get) |> execute

  @doc "Execute a JSON API Request using HTTP POST"
  def create(req), do: req |> Request.method(:post) |> execute

  @doc "Execute a JSON API Request using HTTP PATCH"
  def update(req), do: req |> Request.method(:patch) |> execute

  @doc "Execute a JSON API Request using HTTP DELETE"
  def delete(req), do: req |> Request.method(:delete) |> execute

  @doc """
  Execute a JSON API Request

  Takes a JsonApiClient.Request and preforms the described request.
  """
  def execute(req) do
    url          = Request.get_url(req)
    query_params = Request.get_query_params(req)
    headers      = default_headers()
                   |> Map.merge(req.headers)
                   |> Enum.into([])
    http_options = default_options()
                   |> Map.merge(req.options)
                   |> Map.put(:params, query_params)
                   |> Enum.into([])
    body = Request.get_body(req)

    case HTTPoison.request(
      req.method, url, body, headers, http_options
    ) do
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, resp} -> {:ok, parse_body(resp.body)}
      {:error, err} -> {:error, err}
    end
  end

  defp parse_body(""), do: ""
  defp parse_body(body) do
    body
    |> Poison.decode!
    |> atomize_keys
  end

  defp atomize_keys(map) when is_map(map) do
    for {key, val} <- map, into: %{} do
      {String.to_atom(key), atomize_keys(val)}
    end
  end
  defp atomize_keys(list) when is_list(list), do: Enum.map(list, &atomize_keys/1)
  defp atomize_keys(val), do: val

  defp default_options do
    %{
      timeout: timeout(),
      recv_timeout: timeout(),
    }
  end

  defp default_headers do
    %{
      "Accept"       => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "User-Agent"   => user_agent()              ,
    }
  end

  defp user_agent do
    "ExApiClient/" <> @version <> "/" <> @client_name
  end

  defp timeout do
    @timeout
  end
end