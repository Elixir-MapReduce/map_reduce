defmodule Scheduler do
  require Helper
  require Job
  require Submission
  require Monitor

  use GenServer

  def init(_args) do
    {:ok,
     %{
       monitor: nil,
       child_pids: MapSet.new(),
       submissions: MapSet.new(),
       completed_submissions: MapSet.new(),
       child_responses: [],
       master: nil,
       total_jobs_count: 0,
       received_jobs: MapSet.new()
     }}
  end

  def handle_cast({:switch_dead_worker, pid}, state) do
    %{
      child_pids: child_pids,
      submissions: submissions,
      monitor: monitor
    } = state



    is_member = MapSet.member?(child_pids, pid)

    if false == is_member do
      # TODO: debug this
      {:noreply, state}
    else
      child_pids = MapSet.delete(child_pids, pid)

      # in case of network congestion
      send(pid, {:shutdown})

      orphan_submissions =
        Enum.filter(submissions, fn %Submission{job: %Job{}, worker_pid: process_pid} ->
          process_pid == pid
        end)

      new_worker = GenServer.start(Worker, [5,5]) |> elem(1)
      child_pids = MapSet.put(child_pids, new_worker)

      adopted_submissions =
        orphan_submissions
        |> Enum.map(fn %Submission{job: job} = _submission ->
          %Submission{job: job, worker_pid: new_worker}
        end)

      submit(new_worker, adopted_submissions, monitor)

      all_submissions =
        Enum.filter(submissions, fn el -> !Enum.member?(orphan_submissions, el) end)
        |> Enum.concat(adopted_submissions)
        |> MapSet.new()


      {:noreply, %{state | child_pids: child_pids, submissions: all_submissions}}
    end
  end

  def handle_cast(
        {:schedule_jobs, partitions, workers_count, {job_type, lambda}, caller_pid},
        state
  ) do

    worker_pids = Enum.map(1..workers_count, fn _ -> GenServer.start(Worker, [5 , 5]) |> elem(1) end)
    child_pids = MapSet.new(worker_pids)

#    IO.puts("#{length(partitions)}, #{length(worker_pids)}")
#    IO.inspect(partitions)
    monitor = GenServer.start(Monitor, [worker_pids, self()]) |> elem(1)

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

        submit(worker_pid, [submission], monitor)
      end
    )

    #    {pid, ref} =
    #      spawn_monitor(fn ->
    #        monitor_heartbeats(child_pids)
    #      end)

    {:noreply,
     %{
       state
       | monitor: monitor,
         child_pids: child_pids,
         submissions: submissions,
         master: caller_pid,
         total_jobs_count: length(partitions)
     }}
  end

  def handle_info({:response, response, job_id}, state) do
    %{
      child_responses: child_responses,
      submissions: submissions,
      completed_submissions: completed_submissions,
      master: master,
      total_jobs_count: total_jobs_count,
      received_jobs: received_jobs,
      monitor: monitor
    } = state

    if MapSet.member?(received_jobs, job_id) do
      {:noreply, state}
    else
      current_result = [response | child_responses]

      # IO.puts("#{length(current_result)}, #{total_jobs_count}")

      with true <- length(current_result) == total_jobs_count do
        send(monitor, {:goodbye})
        send(master, {current_result})
      end

      submission = find_submission_with_id(submissions, job_id)
      %Submission{job: job, worker_pid: pid} = submission

      submissions = MapSet.delete(submissions, submission)

      completed_submissions =
        MapSet.put(completed_submissions, %Submission{
          job: %Job{job | status: :finished},
          worker_pid: pid
        })

      {:noreply,
       %{
         state
         | child_responses: current_result,
           submissions: submissions,
           completed_submissions: completed_submissions,
           received_jobs: MapSet.put(received_jobs, job_id)
       }}
    end
  end

  defp submit(worker_pid, submissions, monitor) do
    GenServer.cast(monitor, {:monitor_worker, worker_pid})

    submissions
    |> Enum.each(fn %Submission{job: job} -> GenServer.cast(worker_pid, {job, self()}) end)
  end

  def find_submission_with_id(submissions, job_id) do
    Enum.find(submissions, fn %Submission{job: %Job{job_id: id}} -> id == job_id end)
  end
end
