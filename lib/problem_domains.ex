defmodule ProblemDomains do
  def start_link do
    Task.start_link(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:two_times_plus_1_sum, pid} -> send(pid, {&(&1 * 2 + 1), &(&1 + &2)})
      {:identity_sum, pid} -> send(pid, {& &1, &(&1 + &2)})
    end
  end
end
