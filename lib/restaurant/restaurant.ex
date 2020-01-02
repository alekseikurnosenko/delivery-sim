defmodule Restaurant do
  use GenServer
  use HTTPoison.Base

  require Logger

  @dishes_per_restaurant 25

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, token} = Sim.get_token()
    {:ok, restaurantId} = Restaurant.API.create_restaurant(token)

    Enum.each(1..@dishes_per_restaurant, fn _ ->
      Restaurant.API.create_dish(token, restaurantId)
    end)

    {:ok, _} = WebsocketClient.init(self())

    state = %{
      :token => token,
      :restaurantId => restaurantId
    }

    {:ok, state}
  end

  def handle_info({:websocket, event}, state) do
    handle_event(event, state)
    {:noreply, state}
  end

  defp handle_event(
         %{"type" => "com.delivery.demo.order.OrderPlaced", "payload" => payload},
         %{:restaurantId => restaurantId, :token => token}
       ) do
    {:ok, event} = Poison.decode(payload)

    if event["restaurantId"] == restaurantId do
      Logger.debug("[R] #{restaurantId} New order placed #{event["orderId"]}")

      Process.sleep(500)
      Restaurant.API.start_preparing(token, restaurantId, event["orderId"])

      Process.sleep(500)
      Restaurant.API.finish_preparing(token, restaurantId, event["orderId"])
    end
  end

  defp handle_event(_event, _state) do
  end
end
