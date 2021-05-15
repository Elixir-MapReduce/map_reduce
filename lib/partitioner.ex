defmodule Partitioner do
  def partition(list, parts_count) when is_list(list) do
    Enum.chunk_every(list, ceil(length(list) / parts_count))
  end

  def partition(%Range{} = range, parts_count) do
    partition(range |> Enum.to_list(), parts_count)
  end
end
