defmodule TestChild do
  use GenServer

  @registry :test_registry

  def start_link(index) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(index))
  end

  def stop(index) do
    GenServer.cast(via_tuple(index), :stop)
  end

  def init(args) do
    IO.puts("#{inspect(self())}.init")
    Process.send_after(self(), :ping, 5000)
    {:ok, %{:is_stopped => false}}
  end

  def handle_info(:ping, state) do
    if !state[:is_stopped] do
      # IO.puts("#{inspect(self())}.ping")
      Process.send_after(self(), :ping, 5000)
      {:noreply, state}
    else
      IO.puts("#{inspect(self())}.stop")
      {:stop, :normal, state}
    end
  end

  def handle_cast(:stop, state) do
    {:noreply, %{state | :is_stopped => true}}
  end

  defp via_tuple(index),
    do: {:via, Registry, {@registry, index}}
end
