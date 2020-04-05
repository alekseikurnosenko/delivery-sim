defmodule UserSupervisor do
  use DynamicSupervisor, restart: :transient
  require Logger

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def add_user(index) when is_integer(index) do
    add_user(get_random_opts(index))
  end

  def add_user(opts) when is_map(opts) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: User,
      start: {User, :start_link, [opts]},
      restart: :transient
    })
  end

  def on_child_stopped do
    Logger.info("On child stopped")
    case Supervisor.count_children(__MODULE__) do
      %{active: 0} ->
        Logger.info("Stopping")
        Supervisor.stop(SimSupervisor, :normal)
      _ ->
        :ok
    end
  end

  def get_random_opts(index) do
    %{
      get_opts(index)
      |
      :payment_method_id => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> "PAYMENT_METHOD_SUCCESS"
          _ -> "PAYMENT_METHOD_NOT_ENOUGH_FUNDS"
        end
      end,
      :would_add_to_basket => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> true
          _ -> false
        end
      end,
      :would_order => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> true
          _ -> false
        end
      end,
      :would_restart => true
    }
  end

  def get_opts(index) do
    %{
      :index => index,
      :payment_method_id => fn -> "PAYMENT_METHOD_SUCCESS" end,
      :browse_restaurants_times => 1,
      :dishes_browse_delay => 100,
      :would_add_to_basket => fn -> true end,
      # TODO: Use gaussian function instead
      :dishes_count => fn -> 1 + Kernel.ceil(:rand.uniform() * 2) end,
      :items_per_dish => fn -> 1 + Kernel.ceil(:rand.uniform() * 1) end,
      :item_add_delay => 100,
      :would_order => fn -> true end,
      :would_restart => false
    }
  end
end
