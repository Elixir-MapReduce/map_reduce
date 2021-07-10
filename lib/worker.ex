defmodule Worker do
  use GenServer

  require ETS.Cache, as: Cache

  def init([master]) do
    {:ok,
     %{
       master: master
     }}
  end

  def handle_cast({:map, name_in_cache}, %{master: master} = state) do
    {:ok, data} = Cache.lookup(:splits, name_in_cache)
    {:ok, mapper} = Cache.lookup(:lambdas, :map_lambda)

    # IO.puts("worker starting map")

    result =
      data
      |> mapper.()

    number_of_partitions = 28

    # IO.puts("worker done with map")

    result
    |> Stream.chunk_every(500_000)
    |> Stream.each(fn chunk ->
      chunk
      |> Enum.group_by(fn {key, _value} ->
        Helper.get_hash_for_key(key) |> Integer.mod(number_of_partitions)
      end)
      |> Enum.map(fn {index, group} ->
        GenServer.cast(Bucket, {:insert, index, group})
      end)
    end)
    |> Stream.run()

    # IO.puts("worker saved map result in bucket")

    send(master, {:job_done, nil, self()})

    {:noreply, state}
  end

  def handle_cast({:reduce, name_in_cache}, %{master: master} = state) do
    # IO.puts("reducer called")
    {buffer, storage} = GenServer.call(Bucket, {:get, name_in_cache}, 1_000_000_000)
    {:ok, reducer} = Cache.lookup(:lambdas, :reduce_lambda)

    # IO.puts("reducer received bucket information")

    # IO.puts("concating buffer and storage")
    data = Enum.concat(storage, List.flatten(buffer))
    # IO.puts("concat finished")

    if Enum.empty?(data) == false do
      # IO.puts("starting to execute reduce function")

      data =
        data
        |> Flow.from_enumerable()
        |> Flow.group_by(fn {key, _value} -> key end)
        |> Flow.map(fn {key, group} ->
          {key, Enum.map(group, fn {_key, value} -> value end)}
        end)

      result =
        data
        |> Flow.map(fn key_partition ->
          key_partition
          |> reducer.()
        end)
        |> Enum.to_list()

      # IO.puts("finished executing reduce function")

      file_path = "results/" <> (name_in_cache |> Integer.to_string()) <> ".txt"

      result
      |> Stream.map(fn {k, v} -> "#{k} => #{v}\n" end)
      |> Stream.into(File.stream!(file_path, [:write]))
      |> Stream.run()

      # IO.puts("finished writing reduce to file")
    end

    send(master, {:job_done, nil, self()})
    {:noreply, state}
  end
end
