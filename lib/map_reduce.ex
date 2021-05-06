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
    merger = reduce_lambda

    set_map_reduce(map_lambda, reduce_lambda, solver_pids, acc)

    send_calc_command(solver_pids)

    result = gather_loop(length(solver_pids), accum, merger)
    result
  end

  def main(problem_domain, process_count, collection) do
    domains_pid = elem(ProblemDomains.start_link(), 1)
    solver_pids = spawn_solvers(collection |> Partitioner.partition(process_count))

    send(domains_pid, {problem_domain, self()})

    accum = ProblemDomains.get_init_accum(problem_domain)
    merger = ProblemDomains.merger(problem_domain)

    receive do
      {map, reduce} -> set_map_reduce(map, reduce, solver_pids)
      {map, reduce, init_accum} -> set_map_reduce(map, reduce, solver_pids, init_accum)
    end

    send_calc_command(solver_pids)

    result = gather_loop(length(solver_pids), accum, merger)
    result
  end

  def main(problem_domain) do
    main(problem_domain, 100_000, ProblemDomains.get_sample_list(problem_domain))
  end

  defp gather_loop(0, current_result, _merger) do
    current_result
  end

  defp gather_loop(remaining_responses, current_result, merger) do
    receive do
      {:result, result} ->
        gather_loop(remaining_responses - 1, merger.(current_result, result), merger)
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
