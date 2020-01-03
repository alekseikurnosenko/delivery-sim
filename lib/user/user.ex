defmodule User do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([index]) do
    email = "user_#{index}@delivery.com"
    password = "supersecretpassword"

    Logger.debug("User:init #{email}")

    send(self(), {:login, email, password})
    {:ok, %{}}
  end

  def handle_info({:login, email, password}, state) do
    token =
      case Sim.login(email, password) do
        {:ok, token} ->
          token

        _ ->
          {:ok} = Sim.create_user(email, password)
          {:ok, token} = Sim.login(email, password)
          token
      end

      User.API.set_address(token)
      {:ok, _} = WebsocketClient.init(self())

      send(self(), {:browse})

      {:noreply, %{token: token}}
  end

  def handle_info({:browse}, %{token: token} = state) do
    restaurants = User.API.get_restaurants(token)

    # Browse selection of multiple restaurants
    browse_restaurants_times = 5
    Enum.each(1..browse_restaurants_times, fn _ ->
      restaurant = Enum.random(restaurants)
      User.API.get_dishes(token, restaurant["id"])
      Process.sleep(dish_browse_delay())
    end)

    # Start ordering
    send(self(), {:basket, Enum.random(restaurants)["id"]})
    {:noreply, state}
  end

  def handle_info({:basket, restaurantId}, %{token: token} = state) do
    items_to_add = fn -> Kernel.ceil(:rand.uniform() * 5) + 2 end
    dishes = User.API.get_dishes(token, restaurantId)

    basket = User.API.get_basket(token)

    Enum.each(1..items_to_add.(), fn _ ->
      dishId = Enum.random(dishes)["id"]
      User.API.add_dish_to_basket(token, restaurantId, dishId, items_to_add.())
      User.API.remove_dish_from_basket(token, restaurantId, dishId, items_to_add.() - 1)
      Process.sleep(item_add_delay())
    end)

    User.API.get_basket(token)

    send(self(), {:order})
    {:noreply, state}
  end

  def handle_info({:order}, %{token: token} = state) do
    orderId = User.API.checkout(token)["id"]
    {:noreply, Map.put(state, :orderId, orderId)}
  end

  def handle_info({:websocket, event}, state) do
    type = event["type"]
    {:ok, decoded} = Poison.decode(event["payload"])
    state = handle_event(type, decoded, state)
    {:noreply, state}
  end

  defp handle_event(
    "com.delivery.demo.courier.CourierLocationUpdated",
    _payload,
    state
  ) do
    # Observer courier location
    # FIXME: Right now we would see all couriers!
    state
  end

  defp handle_event(
    "com.delivery.demo.order.OrderDelivered",
    payload,
    %{orderId: orderId} = state
  ) do
    if payload["orderId"] == orderId do
      Process.send_after(self(), {:browse}, new_order_delay())
      Map.delete(state, :orderId)
    else
      state
    end
  end

  defp handle_event(
    _type,
    _payload,
    state
  ) do
    state
  end

  defp dish_browse_delay do
    1000
  end

  defp item_add_delay do
    1000
  end

  defp new_order_delay do
    2000
  end

end
