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

defmodule TestSupervisor do
  use DynamicSupervisor

  @registry :test_registry

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(args) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def add_child(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: TestChild,
      start: {TestChild, :start_link, [index]},
      restart: :transient
    })
  end

  def stop_child(name) do
    # DynamicSupervisor.ch()
    # DynamicSupervisor.terminate_child(__MODULE__, via_tuple(name))
    # Registry.lookup(:test_registry, "1")
  end

  defp via_tuple(index),
    do: {:via, Registry, {@registry, index}}
end

defmodule ActorSupervisor do
  @callback start() :: pid()
  @callback stop(child :: pid()) :: :ok
end

defmodule CourierSupervisor do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def get_opts(index) do
    %{
      :index => index,
      :would_accept => fn ->
        case rand() do
          x when x in 0..50 -> true
          _ -> false
        end
      end,
      :movement_speed => 0.1
    }
  end

  def add_courier(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Courier,
      start: {Courier, :start_link, [get_opts(index)]},
      restart: :permanent
    })
  end

  defp rand() do
    Kernel.round(:rand.uniform() * 100)
  end
end
