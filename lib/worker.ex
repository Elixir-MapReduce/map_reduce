defmodule Worker do
  use GenServer

  def init(_args) do
    {:ok, %{elements: []}}
  end

  def handle_cast({:set_elements, elements}, state) do
    {:noreply, %{state | elements: elements}}
  end

  def handle_call({:reduce, array, reducer}, _from, state) do
    {:reply,
     to_list(array)
     |> Enum.reduce(fn x, acc -> reducer.(acc, x) end), state}
  end

  def handle_call({:map, array, mapper}, _from, state) do
    {:reply, Enum.map(array, mapper), state}
  end

  defp to_list(%Range{} = range) do
    Enum.to_list(range)
  end

  defp to_list(list) when is_list(list) do
    list
  end
end
