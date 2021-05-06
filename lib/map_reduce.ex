defmodule MapReduce do
  require ProblemDomains
  require Partitioner
  require Solver
  require Randomizer

  # not implemented yet
  def main() do
    main(:word_count)
  end

  def main(collection, map_lambda, reduce_lambda, acc, process_count \\ 10_000) do
    solver_pids = Enum.map(collection |> Partitioner.partition(process_count), &spawn_solver/1)

    accum = acc
    reduce = reduce_lambda

    set_map_reduce(map_lambda, reduce_lambda, solver_pids, acc)

    Enum.each(solver_pids, &send_calc_command/1)

    result = gather_loop(length(solver_pids), accum, reduce)
    result
  end

  def main(problem_domain, process_count, collection) do
    domains_pid = elem(GenServer.start(ProblemDomains, []), 1)
    solver_pids = Enum.map(collection |> Partitioner.partition(process_count), &spawn_solver/1)

    accum = GenServer.call(domains_pid, {:get_init_acc, problem_domain})
    reduce = GenServer.call(domains_pid, {:get_reduce, problem_domain})

    case GenServer.call(domains_pid, {problem_domain, self()}) do
      {map, reduce} -> set_map_reduce(map, reduce, solver_pids)
      {map, reduce, init_acc} -> set_map_reduce(map, reduce, solver_pids, init_acc)
    end

    Enum.each(solver_pids, &send_calc_command/1)

    result = gather_loop(length(solver_pids), accum, reduce)
    result
  end

  def main(problem_domain) do
    main(problem_domain, 100_000, GenServer.call(problem_domain, {:get_sample_list}))
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

  def set_map_reduce(map_lambda, reduce_lambda, remaining_pids) do
    set_map_reduce(map_lambda, reduce_lambda, remaining_pids, 0)
  end

  def set_map_reduce(_map_lambda, _reduce_lambda, [], _accum) do
  end

  def set_map_reduce(map_lambda, reduce_lambda, _remaining_pids = [h | t], init_accum) do
    GenServer.cast(h, {:set_map_reduce, map_lambda, reduce_lambda})
    GenServer.cast(h, {:set_init_acc, init_accum})
    set_map_reduce(map_lambda, reduce_lambda, t, init_accum)
  end

  def send_calc_command(solver_pid) do
    GenServer.cast(solver_pid, {:calc, self()})
  end
end
