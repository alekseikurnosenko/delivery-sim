defmodule Restaurant.API do
  require Logger
  use HTTPoison.Base
  import Sim

  def create_restaurant(token) do
    Logger.debug("[R] Creating Restaurant")

    {lat, lon} = Sim.random_location()

    input = %{
      "name" => Faker.Company.name(),
      "address" => %{
        "location" => %{
          "latitude" => lat,
          "longitude" => lon
        },
        "address" => Faker.Address.street_address(),
        "city" => Faker.Address.city(),
        "country" => Faker.Address.country()
      },
      "currency" => "USD"
    }

    case HTTPoison.post(
           "#{endpoint()}/api/restaurants",
           Sim.json(input),
           Sim.headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def me(token) do
    case HTTPoison.get("#{endpoint()}/api/restaurants/me", headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if body && body != "" do
          {:ok, response} = Poison.decode(body)
          {:ok, response}
        else
          {:empty}
        end
    end
  end

  def create_dish(token, restaurantId) do
    Logger.debug("[R] Creating dish #{restaurantId}")

    input = %{
      "name" => Faker.Food.dish(),
      "price" => Float.round(:rand.uniform() * 15, 2)
    }

    HTTPoison.post(
      "#{endpoint()}/api/restaurants/#{restaurantId}/dishes",
      Sim.json(input),
      Sim.headers(token)
    )
  end

  def start_preparing(token, restaurantId, orderId) do
    Logger.debug("[R] Starting preparing #{restaurantId} order #{orderId}")

    HTTPoison.post(
      "#{endpoint()}/api/restaurants/#{restaurantId}/orders/#{orderId}/startPreparing",
      [],
      Sim.headers(token)
    )
  end

  def finish_preparing(token, restaurantId, orderId) do
    Logger.debug("[R] Finishing preparing #{restaurantId} order #{orderId}")

    HTTPoison.post(
      "#{endpoint()}/api/restaurants/#{restaurantId}/orders/#{orderId}/finishPreparing",
      [],
      Sim.headers(token)
    )
  end

  def orders(token, restaurantId, status \\ "Placed") do
    Logger.debug("[R] Fetching orders with status #{status}")

    case HTTPoison.get(
           "#{endpoint()}/api/restaurants/#{restaurantId}/orders?status=#{status}",
           Sim.headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if body && body != "" do
          Poison.decode(body)
        else
          {:empty}
        end
    end
  end
end
