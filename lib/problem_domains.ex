defmodule ProblemDomains do
  require Randomizer
  use GenServer

  defp dict_reducer(map, c) when c == %{} do
    map
  end

  defp dict_reducer(map, c) when is_map(c) do
    [key | _t] = Map.keys(c)
    value = Map.get(c, key)

    dict_reducer(
      Map.update(map, key, value, fn prev_count -> prev_count + value end),
      Map.delete(c, key)
    )
  end

  defp dict_reducer(map, word) do
    Map.update(map, word, 1, fn prev_count -> prev_count + 1 end)
  end

  defp dict_mapper(x) do
    %{x => 1}
  end

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call({:two_times_plus_1_sum, _pid}, _from, _state) do
    {:reply, {&(&1 * 2 + 1), &(&1 + &2)}, %{}}
  end

  def handle_call({:identity_sum, _pid}, _from, _state) do
    {:reply, {& &1, &(&1 + &2)}, %{}}
  end

  def handle_call({:word_count, _pid}, _from, _state) do
    {:reply, {&dict_mapper/1, &dict_reducer/2, %{}}, %{}}
  end

  def handle_call({:get_init_acc, :word_count}, _from, _state) do
    {:reply, %{}, %{}}
  end

  def handle_call({:get_init_acc, :identity_sum}, _from, _state) do
    {:reply, 0, %{}}
  end

  def handle_call({:get_merger, :word_count}, _from, _state) do
    {:reply, &dict_reducer/2, %{}}
  end

  def handle_call({:get_merger, :identity_sum}, _from, _state) do
    {:reply, &(&1 + &2), %{}}
  end

  def handle_call({:get_sample_list, :identity_sum}, _from, _state) do
    {:reply, 1..10_000_000, %{}}
  end

  def handle_call({:get_sample_list, :word_count}, _from, _state) do
    {:reply, Randomizer.randomizer(3, 1_000_000), %{}}
  end
end
