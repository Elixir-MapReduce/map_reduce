defmodule MapReduceTest do
  use ExUnit.Case
  require Partitioner
  require Randomizer
  require Helper
  doctest MapReduce

  test "word_count" do
    {map, reduce} = Helper.get_map_reduce(:word_count)
    collection = [{"hp", "a"}, {"hp", "b"}, {"hp", "a"}, {"hp", "aa"}, {"hp", "a"}]

    assert collection |> MapReduce.solve(map, reduce, 1) == %{
             "a" => 3,
             "aa" => 1,
             "b" => 1
           }
  end

  test "word_total_count" do
    process_count = 50
    total_word_count = 100_000

    words =
      Randomizer.randomizer(7, total_word_count)
      |> Enum.map(fn word -> {"hp", word} end)

    {map, reduce} = Helper.get_map_reduce(:word_count)

    result_count =
      MapReduce.solve(words, map, reduce, process_count)
      |> Enum.reduce(0, fn {_k, v}, acc -> v + acc end)

    assert(result_count == total_word_count)
  end

  test "page_rank" do
    {map, reduce} = Helper.get_map_reduce(:page_rank)
    connections = [{1, 3}, {2, 3}, {4, 5}, {5, 6}]

    result =
      MapReduce.solve(connections, map, reduce)
      |> Enum.map(fn {k, v} -> {k, Enum.sort(v)} end)
      |> Map.new()

    assert(result == %{3 => [1, 2], 5 => [4], 6 => [5]})
  end
end
