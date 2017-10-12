**  ⚠️Warning: This library is currently in an alpha state and is not yet feature complete. It is not recommended for production environments. Stay tuned for a 1.0 release soon. ⚠️**

# JsonApiClient
[![Hex.pm](https://img.shields.io/hexpm/v/json_api_client.svg)](https://hex.pm/packages/json_api_client)
[![Build Docs](https://img.shields.io/badge/hexdocs-release-blue.svg)](https://hexdocs.pm/json_api_client)

A JSON API Client for elixir. ([documentation](https://hexdocs.pm/json_api_client))

## Installation

This package can be installed
by adding `json_api_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_api_client, "~> 0.4.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_api_client](https://hexdocs.pm/json_api_client).

## Usage

```elixir
import JsonApiClient.Request

base_url = "http://example.com/"

# Fetch a resource by URL
{:ok, response} = fetch Request.new(base_url <> "/articles/123")

# build the request by composing helper functions
{:ok, response} = Request.new(base_url <> "/articles")
|> id("123")
|> fetch

# Fetch a list of resources
{:ok, response} = Request.new(base_url <> "/articles")
|> fields(articles: "title,topic", authors: "first-name,last-name,twitter")
|> include(:author)
|> sort(:id)
|> page(size: 10, number: 1)
|> filter(published: true)
|> params(custom1: 1, custom2: 2)
|> fetch

# Delete a resource
{:ok, response} = Request.new(base_url <> "/articles")
|> id("123")
|> delete

# Create a resource
new_article = %Resource{
  type: "articles",
  attributes: %{
    title: "JSON API paints my bikeshed!",
  }
}
{:ok, %{status: 201, doc: %{data: article}}} = Request.new(base_url <> "/articles")
|> resource(new_article)
|> create

# Update a resource
{:ok, %{status: 200, doc: %{data: updated_article}}} = Request.new(base_url <> "/articles")
|> resource(%Resource{article | attributes: %{title: "New Title}})
|> update

```

### Non-compliant servers

For the most part this library assumes that the server you're talking to implements the JSON:API spec correctly and treats deviations from that spec as exceptional (causing `JsonApiClient.execute/1` to return an `{:error, _}` tuple for example). One exception to this rule is the case where a server sends back an invalid body (HTML or some non-json string) along with a 4** or 5** status code. In those cases the body will simple be ignored. See the docs for `JsonApiClient.execute/1` for more details.

### Helpers for common URI structures

The JSON:API specification doesn't provide any guidance on [URI structure](http://jsonapi.org/faq/#position-uri-structure-custom-endpoints), but there is a common convention for REST apis to expose an enpoints with the following structure

```
# fetch a list of resources of a given type
GET /:type_name

# Create a resource of a given type
POST /:type_name

# Fetch/Update/Delete a resource by id
GET /:type_name/:id
PATCH /:type_name/:id
DELETE /:type_name/:id
```

When making requests to API endpoints that follow these conventions you can avoid having to build the full path yourself by adding `JsonApiClient.Resource` to the request.

```elixir
# GET base_url <> "/articles/123"
{:ok, response} = Request.new(base_url)
|> resource(%Resource{id: "123", type: "articles"})
|> fetch

# GET base_url <> "/articles"
{:ok, response} = Request.new(base_url)
|> resource(%Resource{type: "articles"})
|> fetch
```

## Configuration

### client name

Every request made carries a special `User-Agent` header that looks like: `ExApiClient/0.1.0/client_name`. Each client is expected to set its `client_name` via:

```
config :json_api_client, client_name: "yourAppName"
```

### timeout

This library allows its users to specify a timeout for all its service calls by using a `timeout` setting. By default, the timeout is set to 500msecs.

```
config :json_api_client, timeout: 200
```

## TODO

* add module doc to Request and Response
