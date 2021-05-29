defmodule Worker do
  use GenServer

  require Job

  def init([failure_rate, network_congestion_rate]) do
    {:ok, %{failure_rate: failure_rate, network_congestion_rate: network_congestion_rate}}
  end

  def handle_cast(
        {%Job{lambda: lambda, list: list, job_id: id}, pid},
        %{failure_rate: rate} = state
      ) do
    result = lambda.(list)

    with true <- :rand.uniform(10) * :rand.uniform(10) <= rate do
      Process.exit(self(), :kill)
    end

    send(pid, {:response, result, id})

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # do nothing
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :killed}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_info({:shutdown}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_call(:heart_beat, _from, %{network_congestion_rate: rate} = state) do
    with true <- :rand.uniform(10) * :rand.uniform(10) <= rate do
      :timer.sleep(10)
    end

    {:reply, :alive, state}
  end
end
