defmodule Reducer do
  def reduce(list, reduce_lambda) do
    Enum.reduce(list, fn x, acc -> reduce_lambda.(acc, x) end)
  end

  # def reduce(short_list = [h | _t], _reduce_lambda) when length(short_list) < 2 do
  #   h
  # end

  # def reduce([h1, h2 | tail], reduce_lambda) do
  #   reduce([reduce_lambda.(h1, h2) | tail], reduce_lambda)
  # end
end
