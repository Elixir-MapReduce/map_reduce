defmodule Bucket do
  use GenServer

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def handle_cast({:insert, index, group}, state) do
    new_state = insert(state, {index, group})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:persist_buffers, state) do
    new_state =
      Enum.reduce(state, state, fn {key, buffer}, acc ->
        if String.starts_with?(key, "buffer") do
          index = String.slice(key, 6..String.length(key)) |> Integer.parse() |> elem(0)

          persist_index(acc, index, buffer)
        else
          acc
        end
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{}}
  end

  @impl true
  def handle_call({:get, index}, _from, state) do
    buffer = get_buffer(state, index)
    storage = get_storage(state, index)

    {:reply, {buffer, storage}, state}
  end

  defp insert(state, {index, group}) do
    current_capacity = get_capacity(state, index)
    current_length = get_length(state, index)
    new_length = current_length + length(group)

    new_state =
      if new_length > current_capacity do
        current_buffer = get_buffer(state, index) |> List.flatten()
        ret = persist_index(state, index, current_buffer ++ group)
        ret
      else
        set_length(state, index, new_length)
        |> buffer_index(index, group)
      end

    new_state
  end

  defp get_capacity(state, index) do
    Map.get(state, "cap" <> Integer.to_string(index), 10_000_000)
  end

  defp get_length(state, index) do
    Map.get(state, "len" <> Integer.to_string(index), 0)
  end

  defp set_length(state, index, new_len) do
    Map.put(state, "len" <> Integer.to_string(index), new_len)
  end

  defp get_buffer(state, index) do
    Map.get(state, "buffer" <> Integer.to_string(index), [])
  end

  defp get_parts_count(state, index) do
    Map.get(state, "parts" <> Integer.to_string(index), 0)
  end

  defp increase_parts_count(state, index) do
    Map.update(state, "parts" <> Integer.to_string(index), 1, fn value -> value + 1 end)
  end

  defp get_storage(state, index) do
    parts_count = get_parts_count(state, index)

    prefix = "bucket/storage" <> Integer.to_string(index) <> "_parts"

    0..(parts_count - 1)
    |> Enum.reduce([], fn part_index, acc ->
      file_path = prefix <> Integer.to_string(part_index) <> ".txt"

      case File.read(file_path) do
        {:ok, binary} ->
          (binary |> :erlang.binary_to_term()) ++ acc

        {:error, reason} ->
          raise reason
      end
    end)
  end

  defp persist_index(state, index, new_value) do
    new_value = new_value |> List.flatten()

    file_path =
      "bucket/storage" <>
        Integer.to_string(index) <>
        "_parts" <> Integer.to_string(get_parts_count(state, index)) <> ".txt"

    spawn(fn ->
      File.write!(file_path, new_value |> :erlang.term_to_binary(), [:write])
    end)

    state
    |> increase_parts_count(index)
    |> Map.put("buffer" <> Integer.to_string(index), [])
    |> Map.put("len" <> Integer.to_string(index), 0)
  end

  defp buffer_index(state, index, new_group) do
    Map.update(state, "buffer" <> Integer.to_string(index), new_group, fn old_group ->
      [old_group, new_group]
    end)
  end
end
