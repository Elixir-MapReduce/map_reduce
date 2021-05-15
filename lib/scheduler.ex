defmodule Scheduler do
  require Helper
  require Job

  use GenServer

  def init(_args) do
    {:ok,
     %{
       child_pids: MapSet.new(),
       job_pid_pairs: %{},
       child_responses: [],
       master: nil,
       total_job_count: 0
     }}
  end

  def handle_cast({:assign_jobs, partitions, worker_pids, {job_type, lambda}, caller_pid}, state) do
    workers_count = length(worker_pids)

    child_pids = MapSet.new(worker_pids)

    job_pid_pairs =
      partitions
      |> Enum.zip(1..length(partitions))
      |> Enum.map(fn {partition, partition_id} ->
        worker_id = Helper.get_hash_for(partition) |> Integer.mod(workers_count)
        worker_pid = Enum.at(worker_pids, worker_id)
        {{partition, partition_id}, worker_pid}
      end)
      |> Map.new(fn {{partition, job_id}, pid} ->
        {%Job{
           list: partition,
           job_id: job_id,
           job_type: job_type,
           lambda: lambda,
           status: :uncomplete
         }, pid}
      end)

    Enum.each(
      partitions |> Enum.zip(1..length(partitions)),
      fn {_partition, id} ->
        {job, worker_pid} = find_job_with_id(job_pid_pairs, id)

        submit(worker_pid, [{job, worker_pid}])
      end
    )

    {:noreply,
     %{
       state
       | child_pids: child_pids,
         job_pid_pairs: job_pid_pairs,
         master: caller_pid,
         total_job_count: length(partitions)
     }}
  end

  def handle_info({:response, response, job_id}, state) do
    %{
      child_responses: child_responses,
      job_pid_pairs: job_pid_pairs,
      master: master,
      total_job_count: total_job_count
    } = state

    current_result = [response | child_responses]

    with true <- length(current_result) == total_job_count do
      send(master, {current_result})
    end

    {job, pid} = find_job_with_id(job_pid_pairs, job_id)

    job_pid_pairs =
      Map.delete(job_pid_pairs, job)
      |> Map.put(%{job | status: :finished}, pid)

    {:noreply, %{state | child_responses: current_result, job_pid_pairs: job_pid_pairs}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    %{child_pids: child_pids, job_pid_pairs: job_pid_pairs} = state
    child_pids = MapSet.delete(child_pids, pid)

    relevant_uncompleted_pairs =
      Enum.filter(job_pid_pairs, fn {%Job{status: status}, process_pid} ->
        process_pid == pid && status == :uncomplete
      end)

    new_worker = GenServer.start(Worker, []) |> elem(1)

    new_jobs =
      relevant_uncompleted_pairs
      |> Enum.map(fn {job, _pid} -> {job, new_worker} end)

    submit(new_worker, new_jobs)

    all_jobs =
      Enum.concat(
        Enum.filter(job_pid_pairs, fn {%Job{status: status} = _job, process_pid} ->
          status == :finished || process_pid != pid
        end),
        new_jobs
      )
      |> Map.new()

    {:noreply, %{state | child_pids: child_pids, job_pid_pairs: all_jobs}}
  end

  defp submit(worker_pid, job_pid_pairs) do
    Process.monitor(worker_pid)

    job_pid_pairs
    |> Enum.each(fn {job, _worker_pid} -> GenServer.cast(worker_pid, {job, self()}) end)
  end

  def find_job_with_id(job_pid_pairs, job_id) do
    Enum.find(job_pid_pairs, fn {%Job{job_id: id}, _} -> id == job_id end)
  end
end
