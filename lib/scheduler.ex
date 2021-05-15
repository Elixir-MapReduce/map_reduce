defmodule Scheduler do
  require Helper
  require Job
  require Submission

  use GenServer

  def init(_args) do
    {:ok,
     %{
       child_pids: MapSet.new(),
       submissions: MapSet.new(),
       child_responses: [],
       master: nil,
       total_job_count: 0
     }}
  end

  def handle_cast({:assign_jobs, partitions, worker_pids, {job_type, lambda}, caller_pid}, state) do
    workers_count = length(worker_pids)

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

    {:noreply,
     %{
       state
       | child_pids: child_pids,
         submissions: submissions,
         master: caller_pid,
         total_job_count: length(partitions)
     }}
  end

  def handle_info({:response, response, job_id}, state) do
    %{
      child_responses: child_responses,
      submissions: submissions,
      master: master,
      total_job_count: total_job_count
    } = state

    current_result = [response | child_responses]

    with true <- length(current_result) == total_job_count do
      send(master, {current_result})
    end

    submission = find_submission_with_id(submissions, job_id)
    %Submission{job: job, worker_pid: pid} = submission

    submissions =
      MapSet.delete(submissions, submission)
      |> MapSet.put(%Submission{job: %Job{job | status: :finished}, worker_pid: pid})

    {:noreply, %{state | child_responses: current_result, submissions: submissions}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    %{child_pids: child_pids, submissions: submissions} = state
    child_pids = MapSet.delete(child_pids, pid)

    relevant_uncompleted_submissions =
      Enum.filter(submissions, fn %Submission{job: %Job{status: status}, worker_pid: process_pid} ->
        process_pid == pid && status == :uncomplete
      end)

    new_worker = GenServer.start(Worker, []) |> elem(1)

    new_submissions =
      relevant_uncompleted_submissions
      |> Enum.map(fn %Submission{job: job} = _submission ->
        %Submission{job: job, worker_pid: new_worker}
      end)

    submit(new_worker, new_submissions)

    all_submissions =
      Enum.concat(
        Enum.filter(submissions, fn %Submission{
                                      job: %Job{status: status},
                                      worker_pid: process_pid
                                    } ->
          status == :finished || process_pid != pid
        end),
        new_submissions
      )
      |> MapSet.new()

    {:noreply, %{state | child_pids: child_pids, submissions: all_submissions}}
  end

  defp submit(worker_pid, submissions) do
    Process.monitor(worker_pid)

    submissions
    |> Enum.each(fn %Submission{job: job} -> GenServer.cast(worker_pid, {job, self()}) end)
  end

  def find_submission_with_id(submissions, job_id) do
    Enum.find(submissions, fn %Submission{job: %Job{job_id: id}} -> id == job_id end)
  end
end
