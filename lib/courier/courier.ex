defmodule Courier do
  use GenServer
  require Logger
  import Sim

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    {:ok, token} = get_token()

    courier = Courier.API.create(token)
    Courier.API.start_shift(token, courier["id"])
    Courier.API.report_location(token, courier["id"])

    {:ok, _} = WebsocketClient.init(self())

    state = %{
      :token => token,
      :courierId => courier["id"],
      :orders => []
    }
    {:ok, state}
  end

  def handle_info({:websocket, %{"type" => type, "payload" => payload}}, state) do
    {:ok, decoded_payload} = Poison.decode(payload)
    state = handle_event(type, decoded_payload, state)
    {:noreply, state}
  end

  defp handle_event(
         "com.delivery.demo.order.OrderAssigned",
         payload,
         %{courierId: courierId, orders: orders} = state
       ) do
    # If it's aimed at us, remember that we need to pick it up
    # Mb. start moving?
    if payload["courierId"] == courierId do
      Logger.debug("[C] #{courierId} Got assigned new order")

      assignedOrderId = payload["orderId"]
      %{state | orders: [assignedOrderId | orders]}
    else
      state
    end
  end

  defp handle_event(
         "com.delivery.demo.order.OrderPreparationFinished",
         payload,
         %{token: token, courierId: courierId, orders: orders} = state
       ) do
    # If it's an order we are currently checking out
    if Enum.member?(orders, payload["orderId"]) do
      Logger.debug("[C] #{courierId} Assigned order got finished #{payload["orderId"]}")

      Process.sleep(500)
      Courier.API.confirm_pickup(token, courierId, payload["orderId"])

      Process.sleep(500)
      Courier.API.confirm_dropoff(token, courierId, payload["orderId"])

      Map.put(state, :orders, Enum.filter(orders, fn o -> o != payload["orderId"] end))
    else
      state
    end
  end

  defp handle_event(_type, _event, state) do
    state
  end
end
