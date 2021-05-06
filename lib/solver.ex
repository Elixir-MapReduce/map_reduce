defmodule Solver do
  use GenServer
  require Mapper
  require Reducer

  def init(_args) do
    {:ok, %{elements: [], map: [], reduce: [], init_acc: 0}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:add_element, element}, state) do
    {:noreply, %{state | elements: [element | state.elements]}}
  end

  # old : :set_raw_array
  def handle_cast({:set_elements, elements}, state) do
    {:noreply, %{state | elements: elements}}
  end

  def handle_cast({:calc, pid}, state) do
    solve(state.map, state.elements, state.reduce, pid, state.init_acc)
    {:noreply, state}
  end

  def handle_cast({:set_map_reduce, map, reduce}, state) do
    {:noreply, %{state | map: map, reduce: reduce}}
  end

  def handle_cast({:set_init_acc, init_acc}, state) do
    {:noreply, %{state | init_acc: init_acc}}
  end

  defp solve(map_lambda, raw, reduce_lambda, pid, init_accum) do
    send(
      pid,
      {:result, [init_accum | Mapper.apply_map(map_lambda, raw)] |> Reducer.reduce(reduce_lambda)}
    )
  end
end
