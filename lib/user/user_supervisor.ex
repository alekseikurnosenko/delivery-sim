defmodule UserSupervisor do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def add_user(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: User,
      start: {User, :start_link, [get_opts(index)]},
      restart: :permanent
    })
  end

  def get_opts(index) do
    %{
      :index => index,
      :payment_method_id => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> "PAYMENT_METHOD_SUCCESS"
          _ -> "PAYMENT_METHOD_NOT_ENOUGH_FUNDS"
        end
      end,
      :browse_restaurants_times => 1,
      :dishes_browse_delay => 100,
      :would_add_to_basket => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> true
          _ -> false
        end
      end,
      # TODO: Use gaussian function instead
      :dishes_count => fn -> 1 + Kernel.ceil(:rand.uniform() * 2) end,
      :items_per_dish => fn -> 1 + Kernel.ceil(:rand.uniform() * 1) end,
      :item_add_delay => 100,
      :would_order => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..100 -> true
          _ -> false
        end
      end
    }
  end
end
