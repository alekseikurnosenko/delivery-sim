defmodule SimSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_restaurant() do
    DynamicSupervisor.start_child(__MODULE__, Restaurant)
  end

  def add_courier() do
    DynamicSupervisor.start_child(__MODULE__, Courier)
  end

  def order() do
    orders = 5
    Enum.each(1..orders, fn _ ->
      User.start()
    end)
  end
end
