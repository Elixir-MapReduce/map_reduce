defmodule MapReduceTest do
  use ExUnit.Case
  require Partitioner
  require Randomizer
  doctest MapReduce

  test "word_count" do
    assert MapReduce.solve(:word_count, 1, ["a", "b", "aa", "a"]) == %{
             "a" => 2,
             "aa" => 1,
             "b" => 1
           }
  end

  test "identity_list_sum" do
    assert MapReduce.solve(:identity_sum, 2, [1, 4, 6, 8, 1, 8, 3, 6, 2, 7, 3, 7, 8, 4]) == 68
  end

  test "identity_range_sum" do
    n = 100_000_000
    process_count = 100_000
    assert MapReduce.solve(:identity_sum, process_count, 1..n) == n * (n + 1) / 2
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

  test "user_defined_map_reduce" do
    mapper = & &1
    reducer = &(&1 + &2)
    assert([1, 4, 5, 6, 3] |> MapReduce.solve(mapper, reducer) == 19)
  end
end
