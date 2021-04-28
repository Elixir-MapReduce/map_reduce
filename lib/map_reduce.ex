defmodule MapReduce do
  require Mapper
  require ProblemDomains

  def main(args) do
    :hello
  end

  def main() do
    pid = elem(Mapper.start_link(), 1)

    raw_array = [1, 4, 5, 6, 7]

    pid_domains = elem(ProblemDomains.start_link(), 1)

    send(pid_domains, {:two_x_plus1, self()})

    receive do
      {map, reduce} -> send(pid, {:set_map_reduce, map, reduce})
    end

    send(pid, {:set_raw_array, [1, 4, 5, 6, 7]})
    send(pid, {:calc})
  end
end
