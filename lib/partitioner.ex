defmodule Partitioner do
  def start_link do
    Task.start_link(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:partition, list, parts_count, pid} -> send(pid, partition(list, parts_count))
    end
  end

  def partition(list, parts_count) do
    Enum.chunk_every(list, ceil(length(list) / parts_count))
  end
end
