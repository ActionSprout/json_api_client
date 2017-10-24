defmodule JsonApiClient.Middleware.Factory do
  @moduledoc """
  Provides all configured Middlewares.
  """

  def middlewares do
    configured_middlewares() ++ [
      {JsonApiClient.Middleware.DocumentParser, nil},
      {JsonApiClient.Middleware.HTTPClient, nil}
    ]
  end

  defp configured_middlewares do
    Application.get_env(:json_api_client, :middlewares, [])
  end
end
