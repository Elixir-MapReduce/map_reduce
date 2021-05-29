defmodule Worker do
  use GenServer

  require Job

  def init(_args) do
    {:ok, %{}}
  end

  def handle_cast({%Job{lambda: lambda, list: list, job_id: id}, pid}, state) do
    result = lambda.(list)

    # with true <- :rand.uniform(10) * :rand.uniform(10) > 80 do
    # Process.exit(self(), :kill)
    # end

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

  def handle_call(:heart_beat, _from, state) do
    # with true <- :rand.uniform(10) * :rand.uniform(10) > 90 do
    # :timer.sleep(10)
    # end

    {:reply, :alive, state}
  end
end
