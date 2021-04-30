defmodule Reducer do
  def reduce(list, reduce_lambda) do
    Enum.reduce(list, fn x, acc -> reduce_lambda.(acc, x) end)
  end
end
