defmodule ProblemDomains do
  def start_link do
    Task.start_link(fn -> loop() end)
  end

  def dict_reducer(map, c) when c == %{} do
    map
  end

  def dict_reducer(map, c) when is_map(c) do
    [{key, value}] = Enum.take_random(c, 1)

    dict_reducer(
      Map.update(map, key, value, fn prev_count -> prev_count + value end),
      Map.delete(c, key)
    )
  end

  def dict_reducer(map, word) do
    Map.update(map, word, 1, fn prev_count -> prev_count + 1 end)
  end

  defp loop() do
    dict_mapper = fn a -> a end

    receive do
      {:two_times_plus_1_sum, pid} -> send(pid, {&(&1 * 2 + 1), &(&1 + &2)})
      {:identity_sum, pid} -> send(pid, {& &1, &(&1 + &2)})
      {:word_count, pid} -> send(pid, {dict_mapper, &dict_reducer/2, %{}})
    end
  end

  def get_init_accum(:word_count) do
    %{}
  end

  def get_init_accum(:identity_sum) do
    0
  end

  def merger(:word_count) do
    &dict_reducer/2
  end

  def merger(:identity_sum) do
    &(&1 + &2)
  end
end
