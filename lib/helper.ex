defmodule Helper do
  require SampleDomains

  def get_map_reduce(problem_domain) when is_atom(problem_domain) do
    domains_pid = elem(GenServer.start(SampleDomains, []), 1)

    GenServer.call(domains_pid, {problem_domain})
  end
end
