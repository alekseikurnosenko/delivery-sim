defmodule SimSupervisor do
  require Logger
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    test()
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_restaurant(index) do
    DynamicSupervisor.start_child(__MODULE__, {Restaurant, [index]})
  end

  def add_courier(index) do
    DynamicSupervisor.start_child(__MODULE__, {Courier, [index]})
  end

  def add_user(index) do
    DynamicSupervisor.start_child(__MODULE__, {User, [index]})
  end

  def test do
    Enum.each(1..10, fn n ->
      add_restaurant(n)
      Process.sleep(1000)
    end)
    Logger.info("Started restaurants")

    Enum.each(1..20, fn n ->
      add_courier(n)
      Process.sleep(1000)
     end)
     Logger.info("Started courier")
  end

  def users(amount \\ 10) do
    Enum.each(1..amount, fn n ->
      add_user(n)
      Process.sleep(1000)
    end)
    Logger.info("Started #{amount} users")
  end
end
