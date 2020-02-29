defmodule Courier.API do
  use HTTPoison.Base
  import Sim
  require Logger

  def start_shift(token, courierId) do
    Logger.debug("[C] starting shift #{courierId}")

    case HTTPoison.post(
           "#{endpoint()}/api/couriers/#{courierId}/startShift",
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

    case HTTPoison.post("#{endpoint()}/api/couriers", json(input), headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def me(token) do
    case HTTPoison.get("#{endpoint()}/api/couriers/me", headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if body && body != "" do
          {:ok, response} = Poison.decode(body)
          {:ok, response}
        else
          {:error}
        end
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
           "#{endpoint()}/api/couriers/#{courierId}/location",
           json(input),
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        nil
    end
  end

  def confirm_pickup(token, courierId, orderId) do
    Logger.debug("[C] confirming pickup #{courierId} for order #{orderId}")

    case HTTPoison.post(
           "#{endpoint()}/api/couriers/#{courierId}/orders/#{orderId}/confirmPickup",
           [],
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def confirm_dropoff(token, courierId, orderId) do
    Logger.debug("[C] confirming dropoff as #{courierId} for order #{orderId}")

    case HTTPoison.post(
           "#{endpoint()}/api/couriers/#{courierId}/orders/#{orderId}/confirmDropoff",
           [],
           headers(token)
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        response
    end
  end

  def acceptDeliveryRequest(token, courierId, orderId) do
    Logger.debug("[C] accepting delivery reqest as #{courierId} for order #{orderId}")

    case HTTPoison.post(
      "#{endpoint()}/api/couriers/#{courierId}/requests/#{orderId}/accept",
      [],
      headers(token)
    ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        {:ok, response}
    end
  end

  def rejectDeliveryRequest(token, courierId, orderId) do
    Logger.debug("[C] rejecting delivery reqest as #{courierId} for order #{orderId}")

    case HTTPoison.post(
      "#{endpoint()}/api/couriers/#{courierId}/requests/#{orderId}/reject",
      [],
      headers(token)
    ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # {:ok, response} = Poison.decode(body)
        # {:ok, response}
        {:ok}
    end
  end

end
