defmodule RomeoJulietTest do
  def start(process_count) do
    words = Helper.get_words("Romeo&Juliet.txt")

    chunks = Enum.chunk_every(words, 3000)

    collection =
      chunks
      |> Enum.zip(1..10000)
      |> Enum.map(fn {chunk, chunk_id} -> {"part#{chunk_id}", chunk} end)

    # collection = [{"Romeo and Juliet", words}]

    {map, reduce} = Helper.get_map_reduce(:word_count)

    {duration, _} =
      Helper.get_benchmark(fn -> MapReduce.solve(collection, map, reduce, process_count) end)

    IO.puts(duration)
    # result |> Helper.persist()
  end

  def loop(range) do
    Enum.each(range, fn x -> start(x) end)
  end
end
