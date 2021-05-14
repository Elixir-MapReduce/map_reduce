defmodule SampleDomains do
  require Randomizer

  def dict_reducer(x, y), do: %{get_key(x) => get_value(y) + get_value(x)}

  defp get_key(x), do: Map.keys(x) |> List.first()

  defp get_value(x), do: Map.values(x) |> List.first()

  def dict_mapper(x), do: %{x => 1}

  def map_reduce({:word_count}), do: {&dict_mapper/1, &dict_reducer/2}

  def map_reduce({:page_rank}), do: {&link_mapper/1, &link_reducer/2}

  def link_mapper({source, target}), do: %{target => [source]}

  def link_reducer(a, b), do: %{get_key(a) => Enum.concat(get_value(a), get_value(b))}
end
