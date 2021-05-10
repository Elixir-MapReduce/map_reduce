defmodule MapReduce do
  require SampleDomains
  require Partitioner
  require Worker
  require Randomizer

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
      collection
      |> Partitioner.partition(process_count)
      |> Task.async_stream(
        fn c -> Enum.map(c, map_lambda) end,
        max_concurrency: process_count,
        ordered: false
      )
      |> Enum.map(fn {:ok, list} -> list end)
      |> List.flatten()
      |> Enum.group_by(fn x ->
        Map.keys(x)
        |> List.first()
      end)
      |> Map.values()
      |> Enum.map(&spawn_worker/1)

    #    worker_pids = Enum.map(collection |> Partitioner.partition(process_count), &spawn_worker/1)

    reduce = reduce_lambda

    Enum.each(
      worker_pids,
      fn worker_pid ->
        GenServer.cast(worker_pid, {:set_map_reduce, map_lambda, reduce_lambda})
      end
    )

    Enum.each(worker_pids, &send_calc_command/1)

    result = gather_loop(length(worker_pids), reduce)
    result
  end

  def solve(problem_domain) do
    domains_pid = elem(GenServer.start(SampleDomains, []), 1)

    solve(
      problem_domain,
      100_000,
      GenServer.call(domains_pid, {:get_sample_list, problem_domain}, 10000)
    )
  end

  defp gather_loop(remaining_pids, reduce) do
    receive do
      {:result, result} ->
        gather_loop(remaining_pids - 1, result, reduce)
    end
  end

  defp gather_loop(0, current_result, _reduce) do
    current_result
  end

  defp gather_loop(remaining_responses, current_result, reduce) do
    receive do
      {:result, result} ->
        gather_loop(remaining_responses - 1, Map.merge(current_result, result), reduce)
    end
  end

  def spawn_worker(collection) do
    worker_pid = elem(GenServer.start(Worker, []), 1)
    GenServer.cast(worker_pid, {:set_elements, collection})
    worker_pid
  end

  def send_calc_command(worker_pid) do
    GenServer.cast(worker_pid, {:calc, self()})
  end
end
