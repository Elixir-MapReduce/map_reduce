defmodule Mapper do
  require Reducer

  def start_link do
    Task.start_link(fn -> loop([], [], []) end)
  end

  defp loop(map_lambda, raw, reduce_lambda) do
    receive do
      {:add_raw_element, value} -> loop(map_lambda, [value | raw], reduce_lambda)
      {:set_raw_array, values} -> loop(map_lambda, values, reduce_lambda)
      {:calc} -> apply_map_reduce(map_lambda, raw, reduce_lambda)
      {:set_map_reduce, map_lambda, reduce_lambda} -> loop(map_lambda, raw, reduce_lambda)
    end
  end

  defp apply_map_reduce(map_lambda, raw, reduce_lambda) do
    IO.puts("raw list:  #{list_to_string(raw)}")
    result = apply_map(map_lambda, raw, [])
    IO.puts("result before reduce: #{list_to_string(result)}")
    final_result = Reducer.reduce(result, reduce_lambda)
    IO.puts("final result: #{final_result}")
  end

  defp apply_map(_map_lambda, [], result) do
    result |> Enum.reverse()
  end

  defp apply_map(map_lambda, [h | t], result) do
    apply_map(map_lambda, t, [map_lambda.(h) | result])
  end

  defp list_to_string(list) do
    Enum.join(list, ", ")
  end
end
