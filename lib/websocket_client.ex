defmodule WebsocketClient do
  use WebSockex
  require Logger

  def init(parent) do
    state = %{
      :parent => parent
    }

    {:ok, _pid} = WebSockex.start_link("ws://localhost:8080/", __MODULE__, state, [])
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
end
