defmodule MapReduce do
  require ProblemDomains
  require Partitioner
  require Solver

  def main(_args) do
    :hello
  end

  def main() do
    partition_count = 100_000


    domains_pid = elem(ProblemDomains.start_link(), 1)
    solver_pids = spawn_solvers(Enum.to_list(1..1_000_000) |> Partitioner.partition(partition_count))

    IO.inspect(solver_pids)

    send(domains_pid, {:identity_sum, self()})

    receive do
      {map, reduce} -> set_map_reduce(map, reduce, solver_pids)
    end

    send_calc_command(solver_pids)

    gather_loop(length(solver_pids), 0)
  end

  defp gather_loop(0, current_result) do
    current_result
  end

  defp gather_loop(remaining_responses, current_result) do
    receive do
      {:result, result} -> gather_loop(remaining_responses - 1, current_result + result)
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
    raw_array = h
    send(solver_pid, {:set_raw_array, raw_array})
    spawn_solvers(t, [solver_pid | solver_pids])
  end

  def set_map_reduce(_map_lambda, _reduce_lambda, []) do
  end

  def set_map_reduce(map_lambda, reduce_lambda, _remaining_pids = [h | t]) do
    send(h, {:set_map_reduce, map_lambda, reduce_lambda})
    set_map_reduce(map_lambda, reduce_lambda, t)
  end

  def send_calc_command([]) do
  end

  def send_calc_command(_remaining_pids = [h | t]) do
    send(h, {:calc, self()})
    send_calc_command(t)
  end
end
