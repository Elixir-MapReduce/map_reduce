defmodule SampleDomains do
  def word_reducer({word, values}), do: {word, Enum.reduce(values, 0, fn x, acc -> x + acc end)}

  def word_mapper({_document, words}), do: Enum.map(words, fn word -> {word, 1} end)

  def link_mapper({source, targets}), do: Enum.map(targets, fn target -> {target, source} end)

  def link_reducer({key, values}),
    do: {key, Enum.reduce(values, [], fn x, acc -> Enum.concat([x], acc) end)}

  def map_reduce({:word_count}), do: {&word_mapper/1, &word_reducer/1}

  def map_reduce({:page_rank}), do: {&link_mapper/1, &link_reducer/1}
end
