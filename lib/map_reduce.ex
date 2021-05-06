defmodule MapReduce do
  require SampleDomains
  require Partitioner
  require Solver
  require Randomizer

  # not implemented yet
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
    solver_pids = Enum.map(collection |> Partitioner.partition(process_count), &spawn_solver/1)

    reduce = reduce_lambda

    Enum.each(solver_pids, fn solver_pid ->
      GenServer.cast(solver_pid, {:set_map_reduce, map_lambda, reduce_lambda})
    end)

    Enum.each(solver_pids, &send_calc_command/1)

    result = gather_loop(length(solver_pids), reduce)
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
        gather_loop(remaining_responses - 1, reduce.(current_result, result), reduce)
    end
  end

  def spawn_solver(collection) do
    solver_pid = elem(GenServer.start(Solver, []), 1)
    GenServer.cast(solver_pid, {:set_elements, collection})
    solver_pid
  end

  def send_calc_command(solver_pid) do
    GenServer.cast(solver_pid, {:calc, self()})
  end
end
