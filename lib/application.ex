defmodule DeliverySim.Application do
  use Application

  @registry :test_registry

  @impl true
  def start(_args, _opts) do
    children = [
      {TestSupervisor, []},
      {Spawner, []},
      {Registry, [keys: :unique, name: @registry]}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]

    Supervisor.start_link(children, opts)
  end
end
