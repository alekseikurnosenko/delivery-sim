defmodule Courier.API do
  use HTTPoison.Base
  import Sim
  require Logger

  def start_shift(token, courierId) do
    Logger.debug("[C] starting shift #{courierId}")

    case HTTPoison.post(
           "http://localhost:8080/api/couriers/#{courierId}/startShift",
           [],
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def create(token) do
    Logger.debug("[C] creating new courier")

    input = %{
      "name" => Faker.Name.name()
    }

    case HTTPoison.post("http://localhost:8080/api/couriers", json(input), headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def report_location(token, courierId, latLng) do
    Logger.debug("[C] reporting location #{courierId}")

    {lat, lng} = latLng

    input = %{
      "latLng" => %{
        "latitude" => lat,
        "longitude" => lng
      }
    }

    case HTTPoison.post(
           "http://localhost:8080/api/couriers/#{courierId}/location",
           json(input),
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def confirm_pickup(token, courierId, orderId) do
    Logger.debug("[C] confirming pickup #{courierId} for order #{orderId}")

    case HTTPoison.post(
           "http://localhost:8080/api/couriers/#{courierId}/orders/#{orderId}/confirmPickup",
           [],
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def confirm_dropoff(token, courierId, orderId) do
    Logger.debug("[C] confirming dropoff #{courierId} for order #{orderId}")

    case HTTPoison.post(
           "http://localhost:8080/api/couriers/#{courierId}/orders/#{orderId}/confirmDropoff",
           [],
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end
end
