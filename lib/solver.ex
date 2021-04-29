defmodule Solver do
  require Mapper
  require Reducer

  def start_link do
    Task.start_link(fn -> loop([], [], []) end)
  end

  defp loop(map_lambda, raw, reduce_lambda) do
    receive do
      {:add_raw_element, value} -> loop(map_lambda, [value | raw], reduce_lambda)
      {:set_raw_array, values} -> loop(map_lambda, values, reduce_lambda)
      {:calc, pid} -> solve(map_lambda, raw, reduce_lambda, pid)
      {:set_map_reduce, map_lambda, reduce_lambda} -> loop(map_lambda, raw, reduce_lambda)
    end
  end

  defp solve(map_lambda, raw, reduce_lambda, pid) do
    send(pid, {:result, Mapper.apply_map(map_lambda, raw) |> Reducer.reduce(reduce_lambda)})
  end
end
