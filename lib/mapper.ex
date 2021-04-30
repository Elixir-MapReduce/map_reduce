defmodule Mapper do
  def apply_map(map_lambda, %Range{} = range) do
    apply_map(map_lambda, Enum.to_list(range))
  end

  def apply_map(map_lambda, list) do
    Enum.map(list, map_lambda)
    # apply_map(map_lambda, list, [])
  end

  # defp apply_map(_map_lambda, [], result) do
  #   result |> Enum.reverse()
  # end

  # defp apply_map(map_lambda, [h | t], result) do
  #   apply_map(map_lambda, t, [map_lambda.(h) | result])
  # end
end
