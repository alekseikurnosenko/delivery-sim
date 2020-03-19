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

# Something that holds required_count / current_count / state(terminating)
# Courier - genServer-api to stop (call backend)
# Courier - backend-api to stop accepting requests
# Courier - update - if no orders and are stopping - stop
