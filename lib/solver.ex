defmodule Solver do
  require Mapper
  require Reducer

  def start_link do
    Task.start_link(fn -> loop([], [], [], 0) end)
  end

  defp loop(map_lambda, raw, reduce_lambda, init_accum) do
    receive do
      {:add_raw_element, value} ->
        loop(map_lambda, [value | raw], reduce_lambda, init_accum)

      {:set_raw_array, values} ->
        loop(map_lambda, values, reduce_lambda, init_accum)

      {:calc, pid} ->
        solve(map_lambda, raw, reduce_lambda, pid, init_accum)

      {:set_map_reduce, map_lambda, reduce_lambda} ->
        loop(map_lambda, raw, reduce_lambda, init_accum)

      {:set_init_accum, accum} ->
        loop(map_lambda, raw, reduce_lambda, accum)
    end
  end

  defp solve(map_lambda, raw, reduce_lambda, pid, init_accum) do
    send(
      pid,
      {:result, [init_accum | Mapper.apply_map(map_lambda, raw)] |> Reducer.reduce(reduce_lambda)}
    )
  end
end
