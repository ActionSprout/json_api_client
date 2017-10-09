defmodule JsonApiClient do
  @moduledoc """
  A client library for interacting with REST APIs that comply with
  the JSON API spec described at http://jsonapi.org
  """

  @client_name Application.get_env(:json_api_client, :client_name)
  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]

  alias __MODULE__.{Request, RequestError, Response}

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
  
  Returns a tuple with `{:ok, %JsonApiClient.esponse{}}` if the http request
  completed and the server response (if any) was valid. Returns 
  `{:error, %JsonApiClient.RequestError{}}` if the http connection failed for 
  some reson.  Invalid server responses will be ignored when the server returns 
  an error status code between 400-599, but if the server returns an invalid 
  response with a 200 level status code this function will return 
  `{:error, %JsonApiClient.RequestError{}}`.
  """
  def execute(req) do
    with {:ok, response} <- do_request(req),
         {:ok, parsed}   <- parse_response(response)
    do
      {:ok, parsed}
    else
      {:error, %RequestError{} = error} -> {:error, error}
      {:error, error} ->
        {:error, %RequestError{
          original_error: error,
          reason: error.reason
        }}
    end
  end

  defp do_request(req) do
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

    HTTPoison.request(req.method, url, body, headers, http_options)
  end

  defp parse_response(response) do
    with {:ok, doc} <- parse_body(response.body) do
      {:ok, %Response{status: response.status_code, doc: doc}}
    else
      {:error, error} ->
        {:error, %RequestError{
          reason: "Parse Error",
          original_error: error,
          status: response.status_code,
        }}
    end
  end

  defp parse_body(""), do: {:ok, nil}
  defp parse_body(body) do
    with {:ok, map} <- Poison.decode(body),
         atomizied <- atomize_keys(map)
    do
      {:ok, atomizied}
    end
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

defmodule JsonApiClient.Resource do
  @moduledoc """
  JSON API Resource Object
  http://jsonapi.org/format/#document-resource-objects
  """

  defstruct(
    id:            nil,
    type:          nil,
    attributes:    nil,
    relationships: nil,
    meta:          nil,
  )
end

defmodule JsonApiClient.Links do
  @moduledoc """
  JSON API Links Object
  http://jsonapi.org/format/#document-links
  """

  defstruct self: nil, related: nil
end
