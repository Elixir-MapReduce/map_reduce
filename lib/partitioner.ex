defmodule Partitioner do
  def start_link do
    Task.start_link(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:partition, list, parts_count, pid} -> send(pid, partition(list, parts_count))
    end
  end

  def partition(list, parts_count) when is_list(list) do
    Enum.chunk_every(list, ceil(length(list) / parts_count))
  end

  def partition(%Range{} = range, parts_count) do
    range_len = range.last - range.first + 1
    single_instance_len = ceil(range_len / parts_count)

    Stream.iterate(
      range.first..(single_instance_len + range.first - 1),
      &((&1.last + 1)..min(range.last, &1.last + single_instance_len))
    )
    |> Enum.take(parts_count)
  end
end
