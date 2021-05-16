defmodule Worker do
  use GenServer

  require Job

  def init(_args) do
    {:ok, %{}}
  end

  def handle_cast({%Job{lambda: lambda, list: list, job_id: id}, pid}, state) do
    spawn_monitor(fn ->
      #      with true <- :rand.uniform(10) * :rand.uniform(10) > 70 do
      #        Process.exit(self(), :normal)
      #      end
      send(pid, {:response, lambda.(list), id})
    end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_info({:shutdown}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_call(:heart_beat, _from, state) do
    #      with true <- :rand.uniform(10) * :rand.uniform(10) > 50 do
    #        :timer.sleep(10000)
    #      end
    {:reply, :alive, state}
  end
end
