defmodule SimSupervisor do
  require Logger
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    Tokens.Repo.start_link()
  end

  def small_test do
    start_link()
    test(1, 1, 1, 0)
  end

  def large_test do
    start_link()
    test(200, 300, 400, 1000)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 999, max_seconds: 999)
  end

  def add_restaurant(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Restaurant,
      start: {Restaurant, :start_link, [index]},
      restart: :permanent
    })
  end

  def add_courier(index) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Courier,
      start: {Courier, :start_link, [index]},
      restart: :permanent
    })
  end

  def add_user(index) do
    opts = %{
      :index => index,
      :payment_method_id => fn ->
        case Kernel.round(:rand.uniform() * 100) do
          x when x in 0..30 -> "PAYMENT_METHOD_SUCCESS"
          x when x in 30..100 -> "PAYMENT_METHOD_NOT_ENOUGH_FUNDS"
        end
      end
    }

    DynamicSupervisor.start_child(__MODULE__, %{
      id: User,
      start: {User, :start_link, [opts]},
      restart: :permanent
    })
  end

  def test(restaurants, couriers, users, delay) do
    Enum.each(1..restaurants, fn n ->
      add_restaurant(n)
      Process.sleep(delay)
    end)

    Logger.info("Started restaurants")

    Enum.each(1..couriers, fn n ->
      add_courier(n)
      Process.sleep(delay)
    end)

    Logger.info("Started couriers")

    Enum.each(1..users, fn n ->
      add_user(n)
      Process.sleep(delay)
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
