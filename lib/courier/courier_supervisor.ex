defmodule CourierSupervisor do
  use DynamicSupervisor, restart: :transient

  def start_link(_args) do
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
