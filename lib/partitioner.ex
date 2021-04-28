defmodule Partitioner do
  def start_link do
    Task.start_link(fn -> loop() end) 
  end

  defp loop() do
    receive do
      {:partition, list, parts_count, pid} -> send(pid, partition(list, parts_count)) 
    end
  end

  defp partition(list, parts_count) do
	Enum.chunk_every(list, ceil(length(s)/parts_count))  	
  end
end