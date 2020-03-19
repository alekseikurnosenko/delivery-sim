defmodule Spawner do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Spawner)
  end

  def init(_opts) do
    state = %{
      :desired_count => 0
    }

    {:ok, state}
  end

  def set_count(count) do
    GenServer.cast(__MODULE__, {:set_count, count})
  end

  def handle_cast({:set_count, count}, state) do
    IO.puts(":set_count")
    Process.send(self(), :update, [])
    {:noreply, %{state | :desired_count => count}}
  end

  def handle_info(:update, state) do
    spec = [{{:"$1", :"$2", :"$3"}, [], [{{:"$1"}}]}]

    result =
      Registry.select(:test_registry, spec)
      |> Enum.map(fn process -> elem(process, 0) end)

    IO.inspect(result)
    current_count = length(result)

    desired_count = state[:desired_count]

    IO.puts("Update #{desired_count} vs #{current_count}")

    if desired_count > current_count do
      index = find_next_index(result)
      IO.puts("Adding #{index}")
      TestSupervisor.add_child(index)
      Process.send(self(), :update, [])
    end

    if desired_count < current_count do
      index = Enum.at(result, 0)
      IO.puts("Stopping #{index}")
      TestChild.stop(index)
      Process.send(self(), :update, [])
    end

    {:noreply, state}
  end

  def find_next_index(list) do
    Enum.to_list(1..10_000)
    |> Enum.filter(fn index -> !Enum.member?(list, index) end)
    |> Enum.take(1)
    |> Enum.at(0)
  end
end
