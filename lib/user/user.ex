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

    # Browse restaurants dishes
    browse_restaurants_times = state[:browse_restaurants_times]
    Enum.each(1..browse_restaurants_times, fn _ ->
      restaurant = Enum.random(restaurants)

      User.API.get_dishes(token, restaurant["id"])

      # Simulate user reading through the dishes
      Process.sleep(state[:dishes_browse_delay])
    end)

    # Order from random restaurnt
    if (state[:would_add_to_basket].()) do
      send(self(), {:basket, Enum.random(restaurants)["id"]})
    else
      Process.send_after(self(), {:setup}, new_order_delay())
    end

    {:noreply, state}
  end

  def handle_info({:basket, restaurantId}, %{token: token} = state) do
    dishes_count = state[:dishes_count]
    items_per_dish = state[:items_per_dish]
    item_add_delay = state[:item_add_delay]

    # Check basket for being empty?
    User.API.get_basket(token)

    dishes = User.API.get_dishes(token, restaurantId)
    # Simulate adding and removing items from basket
    Enum.each(1..dishes_count.(), fn _ ->
      dishId = Enum.random(dishes)["id"]
      User.API.add_dish_to_basket(token, restaurantId, dishId, items_per_dish.())
      User.API.remove_dish_from_basket(token, restaurantId, dishId, items_per_dish.() - 1)
      Process.sleep(item_add_delay)
    end)

    User.API.get_basket(token)

    if (state[:would_order].()) do
      send(self(), {:order})
    else
      Process.send_after(self(), {:setup}, new_order_delay())
    end

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

  defp new_order_delay do
    2000
  end

end
