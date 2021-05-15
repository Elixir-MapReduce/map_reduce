defmodule Worker do
  use GenServer

  require Job

  def init(_args) do
    {:ok, %{}}
  end

  def handle_cast({%Job{lambda: lambda, list: list, job_id: id}, pid}, state) do
    with true <- :rand.uniform(10) * :rand.uniform(10) > 100 do
      Process.exit(self(), :normal)
    end

    send(pid, {:response, lambda.(list), id})
    {:noreply, state}
  end
end
