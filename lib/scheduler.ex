defmodule Scheduler do
  require Helper
  require Job
  require Submission

  use GenServer

  def init(_args) do
    {:ok,
     %{
       monitor: nil,
       child_pids: MapSet.new(),
       submissions: MapSet.new(),
       child_responses: [],
       master: nil,
       total_jobs_count: 0,
       received_jobs: MapSet.new()
     }}
  end

  def handle_cast(
        {:schedule_jobs, partitions, workers_count, {job_type, lambda}, caller_pid},
        state
      ) do
    worker_pids = Enum.map(1..workers_count, fn _ -> GenServer.start(Worker, []) |> elem(1) end)
    child_pids = MapSet.new(worker_pids)

    submissions =
      partitions
      |> Enum.zip(1..length(partitions))
      |> Enum.map(fn {partition, partition_id} ->
        worker_id = Helper.get_hash_for(partition) |> Integer.mod(workers_count)
        worker_pid = Enum.at(worker_pids, worker_id)
        {{partition, partition_id}, worker_pid}
      end)
      |> MapSet.new(fn {{partition, job_id}, pid} ->
        %Submission{
          job: %Job{
            list: partition,
            job_id: job_id,
            job_type: job_type,
            lambda: lambda,
            status: :uncomplete
          },
          worker_pid: pid
        }
      end)

    Enum.each(
      partitions |> Enum.zip(1..length(partitions)),
      fn {_partition, id} ->
        %Submission{worker_pid: worker_pid} =
          submission = find_submission_with_id(submissions, id)

        submit(worker_pid, [submission])
      end
    )

    {pid, ref} =
      spawn_monitor(fn ->
        monitor_heartbeats(child_pids)
      end)

    {:noreply,
     %{
       state
       | monitor: {pid, ref},
         child_pids: child_pids,
         submissions: submissions,
         master: caller_pid,
         total_jobs_count: length(partitions)
     }}
  end

  defp monitor_heartbeats(worker_pids) do
    Enum.each(worker_pids, fn worker_pid ->
      try do
        :alive = GenServer.call(worker_pid, :heart_beat, 200)
      catch
        :exit, _ -> Process.exit(self(), {:kill, worker_pid})
      end
    end)

    monitor_heartbeats(worker_pids)
  end

  def handle_info({:DOWN, _ref, :process, _pid, {:kill, pid}}, state) do
    {:noreply, new_state = %{child_pids: worker_pids}} = switch_dead_worker(pid, state)

    new_monitor =
      spawn_monitor(fn ->
        monitor_heartbeats(worker_pids)
      end)

    {:noreply, %{new_state | monitor: new_monitor, child_pids: worker_pids}}
  end

  def handle_info({:response, response, job_id}, state) do
    %{
      child_responses: child_responses,
      submissions: submissions,
      master: master,
      total_jobs_count: total_jobs_count,
      received_jobs: received_jobs
    } = state

    if MapSet.member?(received_jobs, job_id) do
      {:noreply, state}
    else
      {monitor_pid, _} = Map.get(state, :monitor)

      current_result = [response | child_responses]

      with true <- length(current_result) == total_jobs_count do
        Process.exit(monitor_pid, :normal)
        send(master, {current_result})
        Process.exit(self(), :normal)
      end

      submission = find_submission_with_id(submissions, job_id)
      %Submission{job: job, worker_pid: pid} = submission

      submissions =
        MapSet.delete(submissions, submission)
        |> MapSet.put(%Submission{job: %Job{job | status: :finished}, worker_pid: pid})

      {:noreply,
       %{
         state
         | child_responses: current_result,
           submissions: submissions,
           received_jobs: MapSet.put(received_jobs, job_id)
       }}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    switch_dead_worker(pid, state)
  end

  defp submit(worker_pid, submissions) do
    Process.monitor(worker_pid)

    submissions
    |> Enum.each(fn %Submission{job: job} -> GenServer.cast(worker_pid, {job, self()}) end)
  end

  def find_submission_with_id(submissions, job_id) do
    Enum.find(submissions, fn %Submission{job: %Job{job_id: id}} -> id == job_id end)
  end

  def switch_dead_worker(pid, state) do
    %{child_pids: child_pids, submissions: submissions} = state
    child_pids = MapSet.delete(child_pids, pid)

    # in case of network congestion
    send(pid, {:shutdown})

    orphan_submissions =
      Enum.filter(submissions, fn %Submission{job: %Job{status: status}, worker_pid: process_pid} ->
        process_pid == pid && status == :uncomplete
      end)

    new_worker = GenServer.start(Worker, []) |> elem(1)
    child_pids = MapSet.put(child_pids, new_worker)

    adopted_submissions =
      orphan_submissions
      |> Enum.map(fn %Submission{job: job} = _submission ->
        %Submission{job: job, worker_pid: new_worker}
      end)

    submit(new_worker, adopted_submissions)

    all_submissions =
      Enum.concat(
        Enum.filter(submissions, fn %Submission{
                                      job: %Job{status: status},
                                      worker_pid: process_pid
                                    } ->
          status == :finished || process_pid != pid
        end),
        adopted_submissions
      )
      |> MapSet.new()

    {:noreply, %{state | child_pids: child_pids, submissions: all_submissions}}
  end
end

