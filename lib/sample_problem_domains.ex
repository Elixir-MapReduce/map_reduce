defmodule SampleDomains do
  require Randomizer

  def dict_reducer({word, values}), do: {word, Enum.reduce(values, 0, fn x, acc -> x + acc end)}

  def dict_mapper({_document, word}), do: [{word, 1}]

  def map_reduce({:word_count}), do: {&dict_mapper/1, &dict_reducer/1}

  def map_reduce({:page_rank}), do: {&link_mapper/1, &link_reducer/1}

  def link_mapper({source, target}), do: [{target, [source]}]

  def link_reducer({key, values}),
    do: {key, Enum.reduce(values, [], fn x, acc -> Enum.concat([x], acc) end)}
end
