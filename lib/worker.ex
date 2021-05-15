defmodule Worker do
  use GenServer

  def init(_args) do
    {:ok, %{elements: []}}
  end

  def handle_cast({:set_elements, elements}, state) do
    {:noreply, %{state | elements: elements}}
  end

  def handle_call({:reduce, {key, values}, reducer}, _from, state) do
    {:reply, reducer.({key, values}), state}
  end

  def handle_call({:map, array, mapper}, _from, state) do
    {:reply, Enum.map(array, mapper), state}
  end
end
