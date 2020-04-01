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

  def stop_child(index) do
    TestChild.stop(index)
  end

  def child_indexes do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> Registry.keys(@registry, pid) |> List.first end)
  end
end

defmodule ActorSupervisor do
  @callback start() :: pid()
  @callback stop(child :: pid()) :: :ok
end
