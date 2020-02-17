defmodule User do
  use GenServer, restart: :permanent
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get_credentials(index) do
    {"user_#{index}@delivery.com", "supersecretpassword"}
  end

  def init(opts) do
    Logger.info("#{opts[:payment_method_id].()}")
    {email,password} = get_credentials(opts[:index])

    Logger.info("User:init #{email} #{inspect(self())}")

    send(self(), {:login, email, password})
    {:ok, opts}
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

      {:ok, _} = WebsocketClient.init(self(), token)

      # NOTE: if the process crashes while running, we might have non-empty basket

      send(self(), {:setup})
      Logger.info("After send")

      {:noreply, Map.put(state, :token, token)}
  end

  def handle_info({:setup}, state) do
    Logger.info("handle info setup")
    token = state[:token]
    User.API.set_address(token)

    payment_method_id = state[:payment_method_id].()
    User.API.set_payment_method(token, payment_method_id)

    send(self(), {:browse})

    {:noreply, state}
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
    dishes_count = fn -> Kernel.ceil(:rand.uniform() * 2) + 1 end # 1-3 dishes
    items_per_dish = fn -> Kernel.ceil(:rand.uniform() * 1) + 1 end # 1-2 per dish
    dishes = User.API.get_dishes(token, restaurantId)

    # Check basket for being empty?
    basket = User.API.get_basket(token)


    Enum.each(1..dishes_count.(), fn _ ->
      dishId = Enum.random(dishes)["id"]
      User.API.add_dish_to_basket(token, restaurantId, dishId, items_per_dish.())
      User.API.remove_dish_from_basket(token, restaurantId, dishId, items_per_dish.() - 1)
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

  def handle_info({:ssl_closed, some}, state) do
    IO.inspect(some)
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
      Logger.debug("[U] Order #{orderId} received, starting again")
      Process.send_after(self(), {:setup}, new_order_delay())
      Map.delete(state, :orderId)
    else
      state
    end
  end

  defp handle_event(
    "com.delivery.demo.order.OrderCanceled",
    payload,
    %{orderId: orderId} = state
  ) do
    if payload["orderId"] == orderId do
      Logger.debug("[U] Order #{orderId} canceled, starting again")
      Process.send_after(self(), {:setup}, new_order_delay())
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
