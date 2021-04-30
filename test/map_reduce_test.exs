defmodule MapReduceTest do
  use ExUnit.Case
  doctest MapReduce

  test "word_count" do
    assert MapReduce.main(:word_count, 1,  ["a", "b", "aa", "a"]) == %{"a" => 2, "aa" => 1, "b" => 1}
  end


  test "identity_sum" do
    assert MapReduce.main(:identity_sum, 2,  [1,4,6,8,1,8,3,6,2,7,3,7,8,4]) == 68
  end
end
