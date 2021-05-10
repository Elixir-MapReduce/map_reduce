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
    process_count = 500
    total_word_count = 10_000
    words = Randomizer.randomizer(3, total_word_count)

    result_count =
      MapReduce.solve(:word_count, process_count, words)
      |> Enum.reduce(0, fn {_k, v}, acc -> v + acc end)

    assert(result_count == total_word_count)
  end
end
