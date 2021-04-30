defmodule Mapper do
  def apply_map(map_lambda, %Range{} = range) do
    apply_map(map_lambda, Enum.to_list(range))
  end

  def apply_map(map_lambda, list) do
    Enum.map(list, map_lambda)
  end
end
