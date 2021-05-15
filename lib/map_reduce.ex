defmodule MapReduce do
  require SampleDomains
  require Worker
  require Scheduler

  def solve(collection, map_lambda, reduce_lambda) do
    solve(collection, map_lambda, reduce_lambda, 10_000)
  end

  def solve(collection, map_lambda, reduce_lambda, processes_count) do
    collection
    |> schedule_jobs(processes_count, {:map, map_lambda})

    receive do
      {response} ->
        response
        |> List.flatten()
        |> Enum.group_by(fn {key, _value} -> key end)
        |> Enum.map(fn {k, v} ->
          {k, Enum.reduce(v, [], fn _x = {_a, b}, acc -> Enum.concat(to_list(b), acc) end)}
        end)
        |> schedule_jobs(processes_count, {:reduce, reduce_lambda})
    end

    receive do
      {collection} ->
        collection
        |> Enum.reduce(%{}, fn {key, values}, acc -> Map.merge(%{key => values}, acc) end)
    end
  end

  defp to_list(x) when is_list(x) do
    x
  end

  defp to_list(x), do: [x]

  def schedule_jobs(partitions, workers_count, {job_type, lambda})
      when is_atom(job_type) do
    pid = GenServer.start(Scheduler, []) |> elem(1)
    GenServer.cast(pid, {:schedule_jobs, partitions, workers_count, {job_type, lambda}, self()})
  end
end
