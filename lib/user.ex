defmodule User do
  def start() do
    {:ok, token} = Sim.get_token()

    restaurants = get_restaurants(token)
    restaurant = Enum.random(restaurants)

    dishes = get_dishes(token, restaurant["id"])

    items_to_add = Kernel.ceil(:rand.uniform() * 5) + 2

    Enum.to_list(1..items_to_add)
    |> Enum.each(fn _ ->
      dish = Enum.random(dishes)
      add_dish_to_basket(token, restaurant["id"], dish["id"])
    end)

    get_basket(token)

    checkout(token)

    :ok
  end

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
end
