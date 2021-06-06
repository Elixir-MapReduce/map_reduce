defmodule Scheduler do
  require Helper
  require Job
  require Submission
  require Monitor

  use GenServer

  @worker_failures_rate 0
  @network_congestion_rate 0

  def init(_args) do
    {:ok,
     %{
       monitor: nil,
       workers: MapSet.new(),
       submissions: MapSet.new(),
       completed_submissions: MapSet.new(),
       master: nil
     }}
  end

  def handle_cast({:switch_dead_worker, pid}, state) do
    %{
      workers: workers,
      submissions: submissions,
      monitor: monitor
    } = state

    is_member = MapSet.member?(workers, pid)

    if false == is_member do
      # TODO: debug this
      {:noreply, state}
    else
      workers = MapSet.delete(workers, pid)

      # in case of network congestion
      send(pid, {:shutdown})

      orphan_submissions =
        Enum.filter(submissions, fn %Submission{job: %Job{}, worker_pid: process_pid} ->
          process_pid == pid
        end)

      new_worker =
        GenServer.start(Worker, [@worker_failures_rate, @network_congestion_rate]) |> elem(1)

      workers = MapSet.put(workers, new_worker)

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

      {:noreply, %{state | workers: workers, submissions: all_submissions}}
    end
  end

  def handle_cast(
        {:schedule_jobs, partitions, workers_count, {job_type, lambda}, caller_pid},
        state
      ) do
    worker_pids =
      Enum.map(1..workers_count, fn _ ->
        GenServer.start(Worker, [@worker_failures_rate, @network_congestion_rate]) |> elem(1)
      end)

    workers = MapSet.new(worker_pids)

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

    {:noreply,
     %{
       state
       | monitor: monitor,
         workers: workers,
         submissions: submissions,
         master: caller_pid
     }}
  end

  def handle_info({:response, response, job_id}, state) do
    %{
      submissions: submissions,
      completed_submissions: completed_submissions,
      master: master,
      monitor: monitor
    } = state

    if find_submission_with_id(completed_submissions, job_id) != nil do
      {:noreply, state}
    else
      submission = find_submission_with_id(submissions, job_id)
      %Submission{job: job, worker_pid: pid} = submission

      submissions = MapSet.delete(submissions, submission)

      completed_submissions =
        MapSet.put(completed_submissions, %Submission{
          job: %Job{job | status: :finished},
          result: response,
          worker_pid: pid
        })

      with true <- 0 == MapSet.size(submissions) do
        send(monitor, {:goodbye})

        send(
          master,
          {Enum.map(completed_submissions, fn %Submission{result: result} -> result end)}
        )
      end

      {:noreply,
       %{
         state
         | submissions: submissions,
           completed_submissions: completed_submissions
       }}
    end
  end

  defp submit(worker_pid, submissions, monitor) do
    #GenServer.cast(monitor, {:monitor_worker, worker_pid})

    submissions
    |> Enum.each(fn %Submission{job: job} -> GenServer.cast(worker_pid, {job, self()}) end)
  end

  def find_submission_with_id(submissions, job_id) do
    Enum.find(submissions, fn %Submission{job: %Job{job_id: id}} -> id == job_id end)
  end
end
