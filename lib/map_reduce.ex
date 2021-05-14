defmodule MapReduce do
  require SampleDomains
  require Partitioner
  require Worker
  require Randomizer

  def solve(collection, map_lambda, reduce_lambda) do
    solve(collection, map_lambda, reduce_lambda, 10_000)
  end

  def solve(collection, map_lambda, reduce_lambda, process_count) do
    worker_pids =
      Enum.map(1..process_count, fn _ -> GenServer.start(Worker, []) |> elem(1) end)
      |> List.duplicate(div(length(collection) + process_count - 1, process_count))
      |> List.flatten()

    collection
    |> Partitioner.partition(process_count)
    |> assign_jobs(worker_pids, process_count, {:map, map_lambda})
    |> List.flatten()
    |> Enum.group_by(fn x ->
      Map.keys(x)
      |> List.first()
    end)
    |> Map.values()
    |> assign_jobs(worker_pids, process_count, {:reduce, reduce_lambda})
    |> Enum.reduce(%{}, fn x, acc -> Map.merge(x, acc) end)
  end

  def assign_jobs(partitions, worker_pids, process_count, {job_type, lambda})
      when is_atom(job_type) do
    partitions
    |> Enum.zip(worker_pids)
    |> Task.async_stream(
      fn {parition, worker_pid} -> GenServer.call(worker_pid, {job_type, parition, lambda}) end,
      max_concurrency: process_count,
      ordered: false
    )
    |> Enum.to_list()
    |> Enum.map(fn {:ok, list} -> list end)
  end
end
