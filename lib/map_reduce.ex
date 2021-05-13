defmodule MapReduce do
  require SampleDomains
  require Partitioner
  require Worker
  require Randomizer
  #   collection  
  #   |> MapReduce.solve(process_count, partitions, :problem_domain)
  def solve() do
    solve(:word_count)
  end

  def solve(problem_domain, process_count, collection) when is_atom(problem_domain) do
    domains_pid = elem(GenServer.start(SampleDomains, []), 1)

    case GenServer.call(domains_pid, {problem_domain, self()}) do
      {map, reduce} -> solve(collection, map, reduce, process_count)
    end
  end

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
    |> Enum.zip(worker_pids)
    |> Task.async_stream(
      fn {parition, worker_pid} -> GenServer.call(worker_pid, {:map, parition, map_lambda}) end,
      max_concurrency: process_count,
      ordered: false
    )
    |> Enum.to_list()
    |> Enum.map(fn {:ok, list} -> list end)
    |> List.flatten()
    |> Enum.group_by(fn x ->
      Map.keys(x)
      |> List.first()
    end)
    |> Map.values()
    |> Enum.zip(worker_pids)
    |> Task.async_stream(
      fn {values, worker_pid} -> GenServer.call(worker_pid, {:reduce, values, reduce_lambda}) end,
      max_concurrency: process_count,
      ordered: false
    )
    |> Enum.to_list()
    |> Enum.map(fn {:ok, list} -> list end)
    |> concat_results()

    # result
  end

  def concat_results(list) do
    concat_results(list, %{})
  end

  def concat_results([], current_result) do
    current_result
  end

  def concat_results([h | t], current_result) do
    concat_results(t, Map.merge(current_result, h))
  end

  def solve(problem_domain) do
    domains_pid = elem(GenServer.start(SampleDomains, []), 1)

    solve(
      problem_domain,
      100_000,
      GenServer.call(domains_pid, {:get_sample_list, problem_domain}, 10000)
    )
  end
end
