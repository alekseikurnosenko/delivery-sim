defmodule SimSupervisor do
  use Supervisor
  require Logger

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      CourierSupervisor,
      UserSupervisor,
      RestaurantSupervisor,
      Tokens.Repo
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def small_test do
    test(1, 1, 1, 0)
  end

  def medium_test do
    test(10, 20, 30, 0)
  end

  def large_test do
    test(200, 300, 400, 1000)
  end


  def test(restaurants, couriers, users, delay) do
    Enum.each(1..restaurants, fn n ->
      RestaurantSupervisor.add_restaurant(n)
      Process.sleep(delay)
    end)

    # Sleep to let the create setup everything
    Process.sleep(500)

    Logger.info("Started restaurants")

    Enum.each(1..couriers, fn n ->
      CourierSupervisor.add_courier(n)
      Process.sleep(delay)
    end)

    Logger.info("Started couriers")

    Enum.each(1..users, fn n ->
      UserSupervisor.add_user(n)
      Process.sleep(delay)
    end)

    Logger.info("Started users")
  end

  def limited_test() do
    restaurants = 1
    couriers = 3
    users = 3

    Enum.each(1..restaurants, fn n ->
      RestaurantSupervisor.add_restaurant(n)
      Process.sleep(500)
    end)

    # Sleep to let the create setup everything
    Process.sleep(500)

    Logger.info("Started restaurants")

    Enum.each(1..couriers, fn n ->
      CourierSupervisor.add_courier(n)
      Process.sleep(500)
    end)

    Logger.info("Started couriers")

    Enum.each(1..users, fn n ->
      UserSupervisor.add_user(UserSupervisor.get_opts(n))
      Process.sleep(500)
    end)

    Logger.info("Started users")
  end
  def preload_tokens(restaurants, couriers, users, delay) do
    Tokens.Repo.start_link()

    Logger.info("Loading tokens for restaurants")

    Enum.each(1..restaurants, fn n ->
      {email, password} = Restaurant.get_credentials(n)
      Sim.login_with_auth0(email, password)
      Process.sleep(delay)
    end)

    Logger.info("Loading tokens for couriers")

    Enum.each(1..couriers, fn n ->
      {email, password} = Courier.get_credentials(n)
      Sim.login_with_auth0(email, password)
      Process.sleep(delay)
    end)

    Logger.info("Loading tokens for users")

    Enum.each(1..users, fn n ->
      {email, password} = User.get_credentials(n)
      Sim.login_with_auth0(email, password)
      Process.sleep(delay)
    end)
  end
end
