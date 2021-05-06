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
    solver_pids = spawn_solvers(collection |> Partitioner.partition(process_count))

    accum = acc
    reduce = reduce_lambda

    set_map_reduce(map_lambda, reduce_lambda, solver_pids, acc)

    send_calc_command(solver_pids)

    result = gather_loop(length(solver_pids), accum, reduce)
    result
  end

  def main(problem_domain, process_count, collection) do
    domains_pid = elem(GenServer.start(ProblemDomains, []), 1)
    solver_pids = spawn_solvers(collection |> Partitioner.partition(process_count))

    accum = GenServer.call(domains_pid, {:get_init_acc, problem_domain})
    reduce = GenServer.call(domains_pid, {:get_reduce, problem_domain})

    case GenServer.call(domains_pid, {problem_domain, self()}) do
      {map, reduce} -> set_map_reduce(map, reduce, solver_pids)
      {map, reduce, init_acc} -> set_map_reduce(map, reduce, solver_pids, init_acc)
    end

    send_calc_command(solver_pids)

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

  defp spawn_solvers(list) do
    spawn_solvers(list, [])
  end

  defp spawn_solvers([], solver_pids) do
    solver_pids
  end

  defp spawn_solvers(_list = [h | t], solver_pids) do
    solver_pid = elem(GenServer.start(Solver, []), 1)
    GenServer.cast(solver_pid, {:set_elements, h})
    spawn_solvers(t, [solver_pid | solver_pids])
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

  def send_calc_command([]) do
  end

  def send_calc_command(_remaining_pids = [h | t]) do
    GenServer.cast(h, {:calc, self()})
    send_calc_command(t)
  end
end
