defmodule WebsocketClient do
  use WebSockex
  require Logger

  def init(parent, token) do
    state = %{
      :parent => parent
    }

    case WebSockex.start_link(Sim.ws_endpoint(), __MODULE__, state,
           extra_headers: [Authorization: "Bearer #{token}"]
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, term} -> Logger.error("Failed to connect to WS: #{inspect(term)}")
    end
  end

  def handle_connect(_conn, state) do
    Logger.debug("Websocket Connected")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    {:ok, event} = Poison.decode(msg)
    send(state[:parent], {:websocket, event})
    {:ok, state}
  end

  def handle_disconnect(connection_status_map, state) do
    Logger.error("Websocket disconnected. Reconnecting.")
    {:reconnect, state}
  end
end
