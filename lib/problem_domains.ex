defmodule ProblemDomains do
  def start_link do
    Task.start_link(fn -> loop([], []) end) 
  end

  defp loop(map_lambda, raw) do
    receive do
      {:two_x_plus1, pid} -> send(pid, { &(&1 * 2 + 1)  , &(&1 + &2)})
    end
  end
end