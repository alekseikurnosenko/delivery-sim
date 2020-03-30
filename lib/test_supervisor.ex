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
