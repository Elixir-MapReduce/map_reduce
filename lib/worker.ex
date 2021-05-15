defmodule Worker do
  use GenServer

  def init(_args) do
    {:ok, %{elements: []}}
  end

  def handle_cast({:set_elements, elements}, state) do
    {:noreply, %{state | elements: elements}}
  end

  def handle_call({:reduce, key_values, reducer}, _from, state) do
    {:reply, reducer.(key_values), state}
  end

  def handle_call({:map, key_value, mapper}, _from, state) do
    {:reply, mapper.(key_value), state}
  end
end
