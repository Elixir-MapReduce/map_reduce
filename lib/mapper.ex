defmodule Mapper do
  def apply_map(map_lambda, list) do
    apply_map(map_lambda, list, [])
  end
  
  defp apply_map(_map_lambda, [], result) do
    result |> Enum.reverse()
  end

  defp apply_map(map_lambda, [h | t], result) do
    apply_map(map_lambda, t, [map_lambda.(h) | result])
  end

  # defp list_to_string(list) do
  #   Enum.join(list, ", ")
  # end
end
