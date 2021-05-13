defmodule MapReduceTest do
  use ExUnit.Case
  require Partitioner
  require Randomizer
  doctest MapReduce

  test "word_count" do
    assert MapReduce.solve(:word_count, 1, ["a", "b", "a", "aa", "a"]) == %{
             "a" => 3,
             "aa" => 1,
             "b" => 1
           }
  end

  test "word_total_count" do
    process_count = 400
    total_word_count = 500_000
    words = Randomizer.randomizer(7, total_word_count)

    result_count =
      MapReduce.solve(:word_count, process_count, words)
      |> Enum.reduce(0, fn {_k, v}, acc -> v + acc end)

    assert(result_count == total_word_count)
  end

  test "page_rank" do
    pid = GenServer.start(SampleDomains, []) |> elem(1)
    {map, reduce} = GenServer.call(pid, {:page_rank})
    connections = [{1, 3}, {2, 3}, {4, 5}, {5, 6}]

    assert(MapReduce.solve(connections, map, reduce) == %{3 => [1, 2], 5 => [4], 6 => [5]})
  end
end
