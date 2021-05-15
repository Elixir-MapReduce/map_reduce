defmodule MapReduceTest do
  use ExUnit.Case
  require Helper
  doctest MapReduce

  test "word_count" do
    {map, reduce} = Helper.get_map_reduce(:word_count)
    collection = [{"no_name", ["a", "b", "a", "aa", "a"]}]

    assert collection |> MapReduce.solve(map, reduce, 1) == %{
             "a" => 3,
             "aa" => 1,
             "b" => 1
           }
  end

  test "word_count with different sources" do
    {map, reduce} = Helper.get_map_reduce(:word_count)

    collection = [
      {"document1", ["harry", "potter", "sam", "harry", "jack"]},
      {"document2", ["jack", "potter", "harry", "daniel"]}
    ]

    assert collection |> MapReduce.solve(map, reduce, 2) ==
             %{"daniel" => 1, "harry" => 3, "jack" => 2, "potter" => 2, "sam" => 1}
  end

  test "big word_count total sum" do
    process_count = 10

    words = Helper.get_words("words.txt")
    total_word_count = length(words)

    collection = [{"Romeo and Juliet", words}]

    {map, reduce} = Helper.get_map_reduce(:word_count)

    result_count =
      MapReduce.solve(collection, map, reduce, process_count)
      |> Enum.reduce(0, fn {_k, v}, acc -> v + acc end)

    assert result_count == total_word_count
  end

  test "page_rank" do
    {map, reduce} = Helper.get_map_reduce(:page_rank)
    connections = [{1, [3]}, {2, [3]}, {4, [5]}, {5, [6]}]

    result =
      MapReduce.solve(connections, map, reduce)
      |> Enum.map(fn {k, v} -> {k, Enum.sort(v)} end)
      |> Map.new()

    assert result == %{3 => [1, 2], 5 => [4], 6 => [5]}
  end
end
