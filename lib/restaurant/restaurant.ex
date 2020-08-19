defmodule Restaurant do
  use GenServer, restart: :permanent
  require Logger

  @dishes_per_restaurant 3

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_credentials(index) do
    {"restaurant_#{index}@delivery.com", "supersecretpassword"}
  end

  def init(opts) do
    {email, password} = get_credentials(opts[:index])

    Logger.info("Restaurant:init #{email} #{inspect(self())}")

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

    {:ok, _} = WebsocketClient.init(self(), token)

    state = Map.put(state, :token, token)
    state = Map.put(state, :restaurantId, restaurantId)

    # send(self(), {:tick})

    {:noreply, state}
  end

  # def handle_info({:tick}, %{token: token, restaurantId: restaurantId} = state) do
    # Fetch orders
    # Start preparing
    # How to make sure that we don't call start multiple times?
    # Process.send_after(self(), {:tick}, 3000)

    # case Restaurant.API.orders(token, restaurantId, "Placed") do
    #   {:ok, orders} ->
    #     orders
    #       |> Enum.each(fn o -> send(self(), {:start, o["id"]}) end)
    #   _ ->
    # end
  #   {:noreply, state}
  # end

  def handle_info({:websocket, event}, state) do
    handle_event(event, state)
    {:noreply, state}
  end

  def handle_info({:start, orderId}, %{token: token, restaurantId: restaurantId} = state) do
    Restaurant.API.start_preparing(token, restaurantId, orderId)
    Process.send_after(self(), {:finish, orderId}, state[:prepare_time])
    {:noreply, state}
  end

  def handle_info({:finish, orderId}, %{token: token, restaurantId: restaurantId} = state) do
    Restaurant.API.finish_preparing(token, restaurantId, orderId)
    {:noreply, state}
  end

  def handle_info({:ssl_closed, some}, state) do
    IO.inspect(some)
    {:noreply, state}
  end

  defp handle_event(
         %{"type" => "com.delivery.demo.order.OrderPaid", "payload" => payload},
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
end
