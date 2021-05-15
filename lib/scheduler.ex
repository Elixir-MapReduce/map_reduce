defmodule Scheduler do
  require Helper
  require Job

  use GenServer

  def init(_args) do
    child_pids = MapSet.new()
    tasks_pid_pairs = %{}
    child_responses = []
    master = nil

    {:ok,
     %{
       child_pids: child_pids,
       tasks_pid_pairs: tasks_pid_pairs,
       child_responses: child_responses,
       master: master
     }}
  end

  def handle_cast({:assign_jobs, partitions, worker_pids, {job_type, lambda}, caller_pid}, state) do
    workers_count = length(worker_pids)

    child_pids = MapSet.new(worker_pids)

    tasks_pid_pairs =
      partitions
      |> Enum.zip(1..length(partitions))
      |> Enum.map(fn {partition, partition_id} ->
        worker_id = Helper.get_hash_for(partition) |> Integer.mod(workers_count)
        worker_pid = Enum.at(worker_pids, worker_id)
        {{partition, partition_id}, worker_pid}
      end)
      |> Map.new(fn {{partition, task_id}, pid} ->
        {%Job{
           list: partition,
           task_id: task_id,
           task_type: job_type,
           lambda: lambda,
           status: :uncomplete
         }, pid}
      end)

    Enum.each(
      partitions |> Enum.zip(1..length(partitions)),
      fn {_partition, id} ->
        {task, worker_pid} =
          Enum.filter(tasks_pid_pairs, fn {%Job{task_id: task_id} = _task, _pid} ->
            id == task_id
          end)
          |> List.first()

        Process.monitor(worker_pid)

        GenServer.cast(worker_pid, {task, self()})
      end
    )

    {:noreply,
     %{state | child_pids: child_pids, tasks_pid_pairs: tasks_pid_pairs, master: caller_pid}}
  end

  def handle_info({:response, response, job_id}, state) do
    current_result = [response | Map.get(state, :child_responses)]

    with true <- length(current_result) == length(Map.keys(Map.get(state, :tasks_pid_pairs))) do
      send(Map.get(state, :master), {current_result})
    end

    {job, pid} =
      Enum.filter(Map.get(state, :tasks_pid_pairs), fn {%Job{task_id: id} = _job, _pid} ->
        id == job_id
      end)
      |> List.first()

    tasks_pid_pairs = Map.delete(Map.get(state, :tasks_pid_pairs), job)
    tasks_pid_pairs = Map.put(tasks_pid_pairs, %{job | status: :finished}, pid)

    {:noreply, %{state | child_responses: current_result, tasks_pid_pairs: tasks_pid_pairs}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    %{child_pids: child_pids, tasks_pid_pairs: tasks_pid_pairs} = state
    child_pids = MapSet.delete(child_pids, pid)

    relevant_uncompleted_pairs =
      Enum.filter(tasks_pid_pairs, fn {%Job{status: status}, process_pid} ->
        process_pid == pid && status == :uncomplete
      end)

    new_worker = GenServer.start(Worker, []) |> elem(1)

    new_tasks =
      relevant_uncompleted_pairs
      |> Enum.map(fn {task, _pid} -> {task, new_worker} end)

    Process.monitor(new_worker)

    new_tasks
    |> Enum.each(fn {task, _new_worker} -> GenServer.cast(new_worker, {task, self()}) end)

    all_tasks =
      Enum.concat(
        Enum.filter(tasks_pid_pairs, fn {%Job{status: status} = _task, process_pid} ->
          status == :finished || process_pid != pid
        end),
        new_tasks
      )
      |> Map.new()

    {:noreply, %{state | child_pids: child_pids, tasks_pid_pairs: all_tasks}}
  end
end
