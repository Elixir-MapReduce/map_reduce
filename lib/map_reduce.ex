defmodule MapReduce do
  require Mapper
  require ProblemDomains

  def main(_args) do
    :hello
  end

  def main() do
    mapper_pid = elem(Mapper.start_link(), 1)

    raw_array = [1, 4, 5, 6, 7]

    domains_pid = elem(ProblemDomains.start_link(), 1)

    send(domains_pid, {:two_x_plus1, self()})

    receive do
      {map, reduce} -> send(mapper_pid, {:set_map_reduce, map, reduce})
    end

    send(mapper_pid, {:set_raw_array, raw_array})
    send(mapper_pid, {:calc})
  end
end
