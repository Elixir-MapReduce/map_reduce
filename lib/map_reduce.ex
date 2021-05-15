defmodule MapReduce do
  require SampleDomains
  require Partitioner
  require Worker
  require Randomizer

  def solve(collection, map_lambda, reduce_lambda) do
    solve(collection, map_lambda, reduce_lambda, 10_000)
  end

  def solve(collection, map_lambda, reduce_lambda, process_count) do
    worker_pids = Enum.map(1..process_count, fn _ -> GenServer.start(Worker, []) |> elem(1) end)

    collection
    |> Partitioner.partition(process_count)
    |> assign_jobs(worker_pids, process_count, {:map, map_lambda})
    |> List.flatten()
    |> Enum.group_by(fn {key, _value} -> key end)
    |> Enum.map(fn {k, v} ->
      {k, Enum.reduce(v, [], fn _x = {_a, b}, acc -> Enum.concat(to_list(b), acc) end)}
    end)
    |> assign_jobs(worker_pids, process_count, {:reduce, reduce_lambda})
    |> Enum.reduce(%{}, fn {key, values}, acc -> Map.merge(%{key => values}, acc) end)
  end

  defp to_list(x) when is_list(x) do
    x
  end

  defp to_list(x), do: [x]

  def get_hash_for({key, _value}) do
    :crypto.hash(:sha, to_string(key)) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  end

  def get_hash_for(_partition = [{key, _value} | _t]) do
    :crypto.hash(:sha, to_string(key)) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  end

  def assign_jobs(partitions, worker_pids, process_count, {job_type, lambda})
      when is_atom(job_type) do
    partitions
    |> Task.async_stream(
      fn partition ->
        worker_id = get_hash_for(partition) |> Integer.mod(length(worker_pids))
        worker_pid = Enum.at(worker_pids, worker_id)
        GenServer.call(worker_pid, {job_type, partition, lambda})
      end,
      max_concurrency: process_count,
      ordered: false
    )
    |> Enum.to_list()
    |> Enum.map(fn {:ok, list} -> list end)
  end
end
