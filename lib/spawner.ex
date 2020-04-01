defmodule Spawner do
  use GenServer

  @registry :test_registry

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

    result = TestSupervisor.child_indexes()
    IO.inspect(result)

    current_count = length(result)
    desired_count = state[:desired_count]
    IO.puts("Update #{desired_count} vs #{current_count}")

    if desired_count > current_count do
      0..(desired_count - current_count - 1)
      |> Enum.each(fn _ ->
        next_index = find_next_index()
        IO.puts("Adding #{next_index}")
        TestSupervisor.add_child(next_index)
      end)
    end

    if desired_count < current_count do
      0..(current_count - desired_count - 1)
      |> Enum.map(fn i -> Enum.at(result, i) end)
      |> Enum.each(fn index ->
        #{_, value} = Registry.lookup(@registry, index) |> List.first()

        IO.puts("Stopping #{index}")
        TestChild.stop(index)
      end)
    end

    {:noreply, state}
  end

  def find_next_index() do
    used_indexes = TestSupervisor.child_indexes()

    Stream.iterate(0, &(&1 + 1))
    |> Stream.filter(fn index -> !Enum.member?(used_indexes, index) end)
    |> Stream.take(1)
    |> Enum.at(0)
  end
end
