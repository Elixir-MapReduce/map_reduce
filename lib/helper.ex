defmodule Helper do
  require SampleDomains

  def get_map_reduce(problem_domain) when is_atom(problem_domain) do
    SampleDomains.map_reduce({problem_domain})
  end
end
