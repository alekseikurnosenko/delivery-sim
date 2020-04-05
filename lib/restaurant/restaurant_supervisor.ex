defmodule RestaurantSupervisor do
  use DynamicSupervisor, restart: :transient

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def add_restaurant(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Restaurant,
      start: {Restaurant, :start_link, [get_opts(index)]},
      restart: :permanent
    })
  end

  def get_opts(index) do
    %{
      :index => index,
      :prepare_time => 5000
    }
  end
end
