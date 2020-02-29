defmodule Courier do
  use GenServer, restart: :permanent
  require Logger
  import Sim

  def start_link(index) do
    GenServer.start_link(__MODULE__, index)
  end

  def get_credentials(index) do
    {"courier_#{index}@delivery.com", "supersecretpassword"}
  end

  def init(index) do
    {email, password} = get_credentials(index)

    Logger.info("Courier:init #{email} #{inspect(self())}")

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

    # Here we need to recover whatever we were doing
    courier =
      case Courier.API.me(token) do
        {:ok, response} ->
          response

        _ ->
          Courier.API.create(token)
      end

    if !courier["onShift"] do
      Courier.API.start_shift(token, courier["id"])
    end

    current_location =
      if !courier["location"] do
        current_location = Sim.random_location()
        Courier.API.report_location(token, courier["id"], current_location)
        current_location
      else
        {courier["location"]["latitude"], courier["location"]["longitude"]}
      end

    orders = get_orders(token)

    state = Map.put(state, :token, token)
    state = Map.put(state, :courierId, courier["id"])
    state = Map.put(state, :location, current_location)
    state = Map.put(state, :orders, orders)

    {:ok, _} = WebsocketClient.init(self(), token)

    Process.send_after(self(), :update, 500)

    {:noreply, state}
  end

  def handle_info(
        :update,
        %{orders: orders, token: token} = state
      ) do
    order = List.first(orders)

    new_state =
      if order != nil do
        # Handle pickup
        cond do
          order[:did_pickup] == false -> handle_pickup(order, state)
          order[:did_dropoff] == false -> handle_dropoff(order, state)
          true -> %{state | orders: Enum.drop(orders, 1)}
        end
      else
        # Might that we've missed the update
        # Force refresh
        Process.sleep(10000)
        %{state | orders: get_orders(token)}
      end

    Process.send_after(self(), :update, 500)
    {:noreply, new_state}
  end

  def handle_info({:websocket, %{"type" => type, "payload" => payload}}, state) do
    {:ok, decoded_payload} = Poison.decode(payload)
    state = handle_event(type, decoded_payload, state)
    {:noreply, state}
  end

  def handle_info({:ssl_closed, some}, state) do
    IO.inspect(some)
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

      %{
        state
        | location: new_location,
          orders: List.update_at(orders, 0, fn _ -> %{order | at_pickup: at_pickup} end)
      }
    else
      if order[:can_pickup] == false do
        # Might that we've missed the update
        # Force refresh
        Process.sleep(5000)
        %{state | orders: get_orders(token)}
      else
        Courier.API.confirm_pickup(token, courierId, order[:orderId])

        %{
          state
          | orders: List.update_at(orders, 0, fn _ -> %{order | did_pickup: true} end)
        }
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

      %{
        state
        | location: new_location,
          orders: List.update_at(orders, 0, fn _ -> %{order | at_dropoff: at_dropoff} end)
      }
    else
      if order[:can_dropoff] == false do
        # Wait
        state
      else
        Courier.API.confirm_dropoff(token, courierId, order[:orderId])

        %{
          state
          | orders: List.update_at(orders, 0, fn _ -> %{order | did_dropoff: true} end)
        }
      end
    end
  end

  defp handle_event(
         "com.delivery.demo.order.OrderAssigned",
         payload,
         %{courierId: courierId, orders: orders} = state
       ) do
    # If it's aimed at us, remember that we need to pick it up
    # Mb. start moving?
    if payload["courierId"] != courierId do
      raise "Receieved event of another courier: my:#{courierId} vs #{payload["courierId"]}"
    end

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

    %{state | orders: Enum.concat(orders, [order])}
  end

  defp handle_event(
         "com.delivery.demo.order.OrderPreparationFinished",
         payload,
         %{courierId: courierId, orders: orders} = state
       ) do
    # If it's an order we are currently checking out
    index = Enum.find_index(orders, fn o -> o[:orderId] == payload["orderId"] end)

    if index == nil do
      raise "Received event for an untracked order: #{payload["orderId"]}"
    end

    Logger.debug("[C] #{courierId} Assigned order got finished #{payload["orderId"]}")

    %{state | orders: List.update_at(orders, index, fn o -> %{o | can_pickup: true} end)}
  end

  defp handle_event(
         "com.delivery.demo.delivery.DeliveryRequested",
         payload,
         %{courierId: courierId, token: token} = state
       ) do
    if payload["courierId"] != courierId do
      raise "[C] Recieved event of another courier: my:#{courierId} vs #{payload["courierId"]}"
    end

    orderId = payload["orderId"]
    # Accept or reject
    Courier.API.acceptDeliveryRequest(token, courierId, orderId)
    state
  end

  defp handle_event(type, _event, state) do
    Logger.error("[C] Unknown event type: #{type}")
    state
  end

  defp get_orders(token) do
    {:ok, courier} = Courier.API.me(token)

    (courier["activeOrders"] || [])
    |> Enum.map(fn order ->
      %{
        orderId: order["id"],
        pickup: {
          order["restaurant"]["address"]["location"]["latitude"],
          order["restaurant"]["address"]["location"]["longitude"]
        },
        at_pickup: false,
        can_pickup: Enum.member?(["AwaitingPickup", "InDelivery", "Delivered"], order["status"]),
        did_pickup: Enum.member?(["InDelivery", "Delivered"], order["status"]),
        dropoff: {
          order["deliveryAddress"]["location"]["latitude"],
          order["deliveryAddress"]["location"]["longitude"]
        },
        at_dropoff: false,
        can_dropoff: true,
        did_dropoff: order["status"] == "Delivered"
      }
    end)
  end

  defp move_to(location, destination) do
    {current_lat, current_lon} = location
    {dst_lat, dst_lon} = destination
    speed = movement_speed()

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

  defp movement_speed do
    0.01
  end
end
