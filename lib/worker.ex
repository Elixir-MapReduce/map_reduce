defmodule Worker do
  use GenServer

  require Job

  def init(_args) do
    {:ok, %{}}
  end

  #  def handle_cast({:set_elements, elements}, state) do
  #    {:noreply, %{state | elements: elements}}
  #  end

  def handle_cast({%Job{lambda: lambda, list: list, task_id: id}, pid}, state) do
    with true <- :rand.uniform(10) * :rand.uniform(10) > 78 do
      Process.exit(self(), :normal)
    end

    send(pid, {:response, lambda.(list), id})
    {:noreply, state}
  end
end
