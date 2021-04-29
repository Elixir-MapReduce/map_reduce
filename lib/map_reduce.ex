defmodule MapReduce do
  require ProblemDomains
  require Partitioner
  require Solver
  require Randomizer

  # not implemented yet
  def main(_args) do
    :hello
  end

  def main() do
    problem_domain = :word_count
    # problem_domain = :identity_sum

    partition_count = 100_000

    domains_pid = elem(ProblemDomains.start_link(), 1)

    # solver_pids = spawn_solvers(Enum.to_list(1..1_000_000) |> Partitioner.partition(partition_count))

    word_random_collection = Randomizer.randomizer(3, partition_count)
    solver_pids = spawn_solvers(word_random_collection |> Partitioner.partition(partition_count))

    send(domains_pid, {problem_domain, self()})

    accum = ProblemDomains.get_init_accum(problem_domain)
    merger = ProblemDomains.merger(problem_domain)

    receive do
      {map, reduce} -> set_map_reduce(map, reduce, solver_pids)
      {map, reduce, init_accum} -> set_map_reduce(map, reduce, solver_pids, init_accum)
    end

    send_calc_command(solver_pids)

    gather_loop(length(solver_pids), accum, merger)
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
    solver_pid = elem(Solver.start_link(), 1)
    send(solver_pid, {:set_raw_array, h})
    spawn_solvers(t, [solver_pid | solver_pids])
  end

  def set_map_reduce(map_lambda, reduce_lambda, remaining_pids) do
    set_map_reduce(map_lambda, reduce_lambda, remaining_pids, 0)
  end

  def set_map_reduce(_map_lambda, _reduce_lambda, [], _accum) do
  end

  def set_map_reduce(map_lambda, reduce_lambda, _remaining_pids = [h | t], init_accum) do
    send(h, {:set_map_reduce, map_lambda, reduce_lambda})
    send(h, {:set_init_accum, init_accum})
    set_map_reduce(map_lambda, reduce_lambda, t, init_accum)
  end

  def send_calc_command([]) do
  end

  def send_calc_command(_remaining_pids = [h | t]) do
    send(h, {:calc, self()})
    send_calc_command(t)
  end
end
