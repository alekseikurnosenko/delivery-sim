defmodule User do
  def start() do
    {:ok, token} = Sim.get_token()

    User.API.set_address(token)

    restaurants = User.API.get_restaurants(token)
    restaurant = Enum.random(restaurants)

    dishes = User.API.get_dishes(token, restaurant["id"])

    items_to_add = Kernel.ceil(:rand.uniform() * 5) + 2

    Enum.to_list(1..items_to_add)
    |> Enum.each(fn _ ->
      dish = Enum.random(dishes)
      User.API.add_dish_to_basket(token, restaurant["id"], dish["id"])
    end)

    User.API.get_basket(token)

    User.API.checkout(token)

    :ok
  end
end
