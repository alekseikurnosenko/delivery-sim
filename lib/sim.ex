defmodule Sim do
  use HTTPoison.Base
  require Logger

  def endpoint do
    "http://localhost:8080"
    # "https://enigmatic-garden-23553.herokuapp.com"
  end

  def ws_endpoint do
    "ws://localhost:8080/ws"
    # "wss://enigmatic-garden-23553.herokuapp.com/ws"
  end

  def login(email, password) do
    # Try to get user from local DB first
    case Tokens.Repo.get_token(email) do
      %{token: token} ->
        {:ok, token}

      nil ->
        login_with_auth0(email, password)
    end
  end

  def login_with_auth0(email, password) do
    client_id = Application.get_env(:delivery_sim, Sim)[:auth0_client_id]
    client_secret = Application.get_env(:delivery_sim, Sim)[:auth0_client_secret]
    audience = "https://delivery/api"

    payload =
      "grant_type=password&username=#{email}&password=#{password}&audience=#{audience}&scope=&client_id=#{
        client_id
      }&client_secret=#{client_secret}"

    case HTTPoison.post("https://dev-delivery.auth0.com/oauth/token", payload,
           "content-type": "application/x-www-form-urlencoded"
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        token = response["access_token"]
        Tokens.Repo.add_token(email, token)
        {:ok, token}

      {:ok, %HTTPoison.Response{status_code: 403}, body: body} ->
        Logger.error("403: #{body}")
        {:error}

      {:ok, response} ->
        Logger.error(inspect(response))
        {:error}
    end
  end

  def create_user(email, password) do
    {:ok, token} = get_token("https://dev-delivery.auth0.com/api/v2/")

    input = %{
      "email" => email,
      "password" => password,
      "connection" => "Username-Password-Authentication"
    }

    case HTTPoison.post(
           "https://dev-delivery.auth0.com/api/v2/users",
           json(input),
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        {:ok}

      {:ok, response} ->
        Logger.error(inspect(response))
        {:error}
    end
  end

  def get_token(audience \\ "https://delivery/api") do
    client_id = Application.get_env(:delivery_sim, Sim)[:auth0_client_id]
    client_secret = Application.get_env(:delivery_sim, Sim)[:auth0_client_secret]

    json =
      json(%{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "audience" => audience,
        "grant_type" => "client_credentials"
      })

    case HTTPoison.post(
           "https://dev-delivery.auth0.com/oauth/token",
           json,
           "content-type": "application/json"
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        IO.inspect(response)
        {:ok, response["access_token"]}

      rest ->
        IO.inspect(rest)
        {:error}
    end

    # {:ok, @token}
  end

  def json(payload) do
    Poison.encode!(payload)
  end

  def headers(token) do
    [Authorization: "Bearer #{token}", "content-type": "application/json"]
  end

  def random_location() do
    min_lat = 29.624207
    max_lat = 29.939842
    min_lon = -95.571568
    max_lon = -95.190748

    lat = :rand.uniform() * (max_lat - min_lat) + min_lat
    lon = :rand.uniform() * (max_lon - min_lon) + min_lon

    %{
      "latitude" => lat,
      "longitude" => lon
    }

    {lat, lon}
  end
end
