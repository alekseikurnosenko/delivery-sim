defmodule Restaurant do
  use GenServer
  require Logger

  @dishes_per_restaurant 25

  def start_link(index) do
    GenServer.start_link(__MODULE__, index)
  end

  def init([index]) do
    email = "restaurant_#{index}@delivery.com"
    password = "supersecretpassword"

    Logger.debug("Courier:init #{email}")

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

    restaurantId =
      case Restaurant.API.me(token) do
        {:ok, response} ->
          Logger.debug("[R] Found me")
          response["id"]

        _ ->
          Logger.debug("[R] Creating me")
          restaurantId = Restaurant.API.create_restaurant(token)["id"]

          Enum.each(1..@dishes_per_restaurant, fn _ ->
            Restaurant.API.create_dish(token, restaurantId)
          end)

          restaurantId
      end

    {:ok, _} = WebsocketClient.init(self())

    state = Map.put(state, :token, token)
    state = Map.put(state, :restaurantId, restaurantId)

    {:noreply, state}
  end

  def handle_info({:websocket, event}, state) do
    handle_event(event, state)
    {:noreply, state}
  end

  def handle_info({:start, orderId}, %{token: token, restaurantId: restaurantId} = state) do
    Restaurant.API.start_preparing(token, restaurantId, orderId)
    Process.send_after(self(), {:finish, orderId}, prepare_time())
    {:noreply, state}
  end

  def handle_info({:finish, orderId}, %{token: token, restaurantId: restaurantId} = state) do
    Restaurant.API.finish_preparing(token, restaurantId, orderId)
    {:noreply, state}
  end

  defp handle_event(
         %{"type" => "com.delivery.demo.order.OrderPlaced", "payload" => payload},
         %{:restaurantId => restaurantId}
       ) do
    {:ok, event} = Poison.decode(payload)

    if event["restaurantId"] == restaurantId do
      Logger.debug("[R] #{restaurantId} New order placed #{event["orderId"]}")
      Process.send_after(self(), {:start, event["orderId"]}, start_delay())
    end
  end

  defp handle_event(_event, _state) do
  end

  defp start_delay do
    1000
  end

  defp prepare_time do
    3000
  end
end
