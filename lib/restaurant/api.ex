defmodule Restaurant.API do
  require Logger
  use HTTPoison.Base
  import Sim

  def create_restaurant(token) do
    Logger.debug("[R] Creating Restaurant")

    input = %{
      "name" => Faker.Company.name(),
      "address" => %{
        "location" => %{
          "latitude" => :rand.uniform(),
          "longitude" => :rand.uniform()
        },
        "address" => Faker.Address.street_address(),
        "city" => Faker.Address.city(),
        "country" => Faker.Address.country()
      },
      "currency" => "USD"
    }

    case HTTPoison.post(
           "http://localhost:8080/api/restaurants",
           Sim.json(input),
           Sim.headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        {:ok, response["id"]}
    end
  end

  def create_dish(token, restaurantId) do
    Logger.debug("[R] Creating dish #{restaurantId}")

    input = %{
      "name" => Faker.Food.dish(),
      "price" => Float.round(:rand.uniform() * 20, 2)
    }

    HTTPoison.post(
      "http://localhost:8080/api/restaurants/#{restaurantId}/dishes",
      Sim.json(input),
      Sim.headers(token)
    )
  end

  def start_preparing(token, restaurantId, orderId) do
    Logger.debug("[R] Starting preparing #{restaurantId} order #{orderId}")

    HTTPoison.post(
      "http://localhost:8080/api/restaurants/#{restaurantId}/orders/#{orderId}/startPreparing",
      [],
      Sim.headers(token)
    )
  end

  def finish_preparing(token, restaurantId, orderId) do
    Logger.debug("[R] Finishing preparing #{restaurantId} order #{orderId}")

    HTTPoison.post(
      "http://localhost:8080/api/restaurants/#{restaurantId}/orders/#{orderId}/finishPreparing",
      [],
      Sim.headers(token)
    )
  end

end
