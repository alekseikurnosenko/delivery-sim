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
    current_location = Sim.random_location()
    Courier.API.report_location(token, courier["id"], current_location)

    {:ok, _} = WebsocketClient.init(self())

    Process.send_after(self(), :update, 1_000)

    state = %{
      :token => token,
      :courierId => courier["id"],
      :orders => [],
      :location => current_location
    }

    {:ok, state}
  end

  def handle_info(
        :update,
        %{orders: orders} = state
      ) do
    Process.send_after(self(), :update, 1_000)

    order = List.first(orders)

    if order != nil do
      Logger.debug("Order: #{inspect(order)}")
      # Handle pickup
      cond do
        order[:did_pickup] == false -> handle_pickup(order, state)
        order[:did_dropoff] == false -> handle_dropoff(order, state)
        true -> {:noreply, %{state | orders: Enum.drop(orders, 1)}}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info({:websocket, %{"type" => type, "payload" => payload}}, state) do
    {:ok, decoded_payload} = Poison.decode(payload)
    state = handle_event(type, decoded_payload, state)
    {:noreply, state}
  end

  defp handle_pickup(
    order,
    %{token: token, courierId: courierId, location: location, orders: orders} = state
  ) do
    # Ensure we are at pickup point
    if order[:at_pickup] == false do
      {new_location, at_pickup} =
        case move_to(location, order[:pickup]) do
          {:arrived, new_location} -> {new_location, true}
          {:pending, new_location} -> {new_location, false}
        end

      Courier.API.report_location(token, courierId, new_location)

      {:noreply,
       %{
         state
         | location: new_location,
           orders: List.update_at(orders, 0, fn _ -> %{order | at_pickup: at_pickup} end)
       }}
    else
      if order[:can_pickup] == false do
        # Wait
        {:noreply, state}
      else
        Courier.API.confirm_pickup(token, courierId, order[:orderId])

        {:noreply,
         %{
           state
           | orders: List.update_at(orders, 0, fn _ -> %{order | did_pickup: true} end)
         }}
      end
    end
  end

  defp handle_dropoff(
    order,
    %{token: token, courierId: courierId, location: location, orders: orders} = state
  ) do
    # Ensure we are at pickup point
    if order[:at_dropoff] == false do
      {new_location, at_dropoff} =
        case move_to(location, order[:dropoff]) do
          {:arrived, new_location} -> {new_location, true}
          {:pending, new_location} -> {new_location, false}
        end

      Courier.API.report_location(token, courierId, new_location)

      {:noreply,
       %{
         state
         | location: new_location,
           orders: List.update_at(orders, 0, fn _ -> %{order | at_dropoff: at_dropoff} end)
       }}
    else
      if order[:can_dropoff] == false do
        # Wait
        {:noreply, state}
      else
        Courier.API.confirm_dropoff(token, courierId, order[:orderId])

        {:noreply,
         %{
           state
           | orders: List.update_at(orders, 0, fn _ -> %{order | did_dropoff: true} end)
         }}
      end
    end
  end

  defp move_to(location, destination) do
    {current_lat, current_lon} = location
    {dst_lat, dst_lon} = destination
    speed = 0.01

    if abs(current_lat - dst_lat) < speed && abs(current_lon - dst_lon) < speed do
      {:arrived, {dst_lat, dst_lon}}
    else
      lat_diff = dst_lat - current_lat
      lon_diff = dst_lon - current_lon

      vector_distance = :math.sqrt(lat_diff * lat_diff + lon_diff * lon_diff)

      unit_lat_diff = lat_diff / vector_distance
      unit_lon_diff = lon_diff / vector_distance

      move_lat = unit_lat_diff * speed
      move_lon = unit_lon_diff * speed

      new_lat = current_lat + move_lat
      new_lon = current_lon + move_lon

      {:pending, {new_lat, new_lon}}
    end
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

      orderId = payload["orderId"]

      pickup = {
        payload["restaurantAddress"]["location"]["latitude"],
        payload["restaurantAddress"]["location"]["longitude"]
      }

      dropoff = {
        payload["deliveryAddress"]["location"]["latitude"],
        payload["deliveryAddress"]["location"]["longitude"]
      }

      order = %{
        orderId: orderId,
        pickup: pickup,
        at_pickup: false,
        can_pickup: false,
        did_pickup: false,
        dropoff: dropoff,
        at_dropoff: false,
        can_dropoff: true,
        did_dropoff: false
      }

      %{state | orders: [order | orders]}
    else
      state
    end
  end

  defp handle_event(
         "com.delivery.demo.order.OrderPreparationFinished",
         payload,
         %{courierId: courierId, orders: orders} = state
       ) do
    # If it's an order we are currently checking out
    index = Enum.find_index(orders, fn o -> o[:orderId] == payload["orderId"] end)

    if index do
      Logger.debug("[C] #{courierId} Assigned order got finished #{payload["orderId"]}")

      %{state | orders: List.update_at(orders, index, fn o -> %{o | can_pickup: true} end)}
    else
      state
    end
  end

  defp handle_event(_type, _event, state) do
    state
  end
end
