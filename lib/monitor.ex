defmodule Monitor do
  require GenServer

  defp to_map_set(workers) when is_list(workers) do
    MapSet.new(workers)
  end

  defp to_map_set(worker) do
    MapSet.new([worker])
  end

  def init([workers, scheduler]) do
    workers = to_map_set(workers)
    monitor_failure(workers)
    {pid, ref} = spawn_monitor(fn -> monitor_heartbeats(workers) end)

    {
      :ok,
      %{
        heartbeat_loop: {pid, ref},
        workers: workers,
        scheduler: scheduler
      }
    }
  end

  defp monitor_failure(workers) do
    Enum.each(workers, fn worker -> Process.monitor(worker) end)
  end

  defp monitor_heartbeats(worker_pids) do
    Enum.each(worker_pids, fn worker_pid ->
      try do
        :alive = GenServer.call(worker_pid, :heart_beat, 300)
      catch
        :exit, _ ->
          Process.exit(self(), {:heartbeat_loop_dead, worker_pid})
      end
    end)

    :timer.sleep(500)
    monitor_heartbeats(worker_pids)
  end

  def handle_info({:goodbye}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_info(
        {:DOWN, _ref, :process, _pid, {:heartbeat_loop_dead, worker_pid, workers: workers}},
        %{scheduler: scheduler} = state
      ) do
    GenServer.cast(scheduler, {:switch_dead_worker, worker_pid})

    {:noreply, %{state | workers: workers}}
  end

  def handle_info(
        {:DOWN, _ref, :process, worker_pid, _reason},
        %{scheduler: scheduler, workers: workers} = state
      ) do
    GenServer.cast(scheduler, {:switch_dead_worker, worker_pid})

    {:noreply, %{state | workers: workers}}
  end

  def handle_cast(
        {:monitor_worker, worker},
        %{heartbeat_loop: {heartbeat_loop_pid, _}, workers: workers} = state
      ) do
    Process.exit(heartbeat_loop_pid, :normal)

    monitor_failure([worker])
    workers = MapSet.put(workers, worker)

    new_heartbeat_loop =
      spawn_monitor(fn ->
        monitor_heartbeats(workers)
      end)

    {:noreply, %{state | heartbeat_loop: new_heartbeat_loop, workers: workers}}
  end
end
