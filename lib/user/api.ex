defmodule User.API do
  use HTTPoison.Base
  import Sim
  require Logger

  def get_restaurants(token) do
    case HTTPoison.get("http://localhost:8080/api/restaurants", Sim.headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def get_dishes(token, restaurantId) do
    case HTTPoison.get(
           "http://localhost:8080/api/restaurants/#{restaurantId}/dishes",
           Sim.headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def add_dish_to_basket(token, restaurantId, dishId) do
    input = %{
      "dishId" => dishId,
      "restaurantId" => restaurantId,
      "quantity" => 1
    }

    case HTTPoison.post(
           "http://localhost:8080/api/basket/addItem",
           Sim.json(input),
           Sim.headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def get_basket(token) do
    case HTTPoison.get("http://localhost:8080/api/basket", Sim.headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def checkout(token) do
    case HTTPoison.post("http://localhost:8080/api/basket/checkout", [], Sim.headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def set_address(token) do
    {lat, lon} = Sim.random_location()

    input = %{
      "location" => %{
        "latitude" => lat,
        "longitude" => lon
      },
      "address" => "fake",
      "city" => "fake",
      "country" => "fake"
    }

    HTTPoison.post!(
      "http://localhost:8080/api/profile/address",
      Sim.json(input),
      Sim.headers(token)
    )
  end
end
