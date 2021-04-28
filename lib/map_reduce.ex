defmodule MapReduce do
  require Mapper
  require ProblemDomains
  require Partitioner

  def main(_args) do
    :hello
  end

  def main() do
    domains_pid = elem(ProblemDomains.start_link(), 1)


    mapper_pids = spawn_mappers(Enum.to_list(1..1000000) |>  Partitioner.partition(100000))

    IO.inspect(mapper_pids)

    # send(domains_pid, {:two_times_plus_1_sum, self()})
    send(domains_pid, {:identity_sum, self()})
    receive do
      {map, reduce} -> set_map_reduce(map, reduce, mapper_pids)
    end


    send_calc_command(mapper_pids)


    gather_loop(length(mapper_pids), 0)
  end

  defp gather_loop(0, current_result) do
    current_result
  end

  defp gather_loop(remaining_responses, current_result) do
    receive do
      {:result, result} -> gather_loop(remaining_responses - 1 , current_result + result)
    end
  end

  defp spawn_mappers(list) do
    spawn_mappers(list, [])
  end

  defp spawn_mappers([], mapper_pids) do
    mapper_pids
  end

  defp spawn_mappers(list = [h | t], mapper_pids) do
    mapper_pid = elem(Mapper.start_link(), 1)
    raw_array = h
    send(mapper_pid, {:set_raw_array, raw_array})
    spawn_mappers(t, [mapper_pid | mapper_pids])
  end

  def set_map_reduce(map_lambda, reduce_lambda, []) do
  end

  def set_map_reduce(map_lambda, reduce_lambda, remaining_pids = [h | t]) do
    send(h, {:set_map_reduce, map_lambda, reduce_lambda})
    set_map_reduce(map_lambda, reduce_lambda, t)
  end

  def send_calc_command([]) do
  end

  def send_calc_command(remaining_pids = [h | t]) do
    send(h, {:calc, self()})
    send_calc_command(t)
  end

  defp list_to_string(list) do
    Enum.join(list, ", ")
  end


end
