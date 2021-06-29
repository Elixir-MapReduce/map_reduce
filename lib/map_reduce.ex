defmodule MapReduce do
  require ETS.Cache, as: Cache
  require Input

  @file_path "yelp_academic_dataset_review.json"
  @chunk_folder "chunks/"
  @chunked true
  @chunks_count 16

  @stages 16
  @worker_count 8

  def run() do
    chunks = if @chunked do
      Input.from(:chunks, @chunk_folder, @chunks_count)
    else
      Input.from(:file, @file_path)
    end

    anf = fn ->
      map_lambda = fn words ->
        words
        |> Stream.map(fn word ->
          {word, 1}
        end)
      end

      reduce_lambda = fn {key, values} ->
        {key, Enum.sum(values)}
      end
      
      run2(chunks, map_lambda, reduce_lambda)
    end

    {timer1, _} = Helper.get_benchmark(anf)
    IO.inspect(timer1)
  end

  def run2(chunks, map_lambda, reduce_lambda) do
    File.rm_rf("bucket/")
    File.mkdir("bucket/")

    File.rm_rf("results/")
    File.mkdir("results/")

    init_caches(map_lambda, reduce_lambda)

    chunks
    |> Stream.with_index()
    |> Stream.map(fn {chunk, index} ->
      Cache.insert(:splits, index, chunk)
    end)
    |> Stream.run()

    chunks_length = length(chunks)

    master = GenServer.start_link(Master, [@worker_count, chunks_length, self()]) |> elem(1)

    IO.inspect("starting mapping")

    0..(chunks_length - 1)
    |> Stream.map(fn index ->
      GenServer.cast(master, {:map_phase, index, nil})
    end)
    |> Stream.run()

    receive do
      {:job_done} -> nil
    end

    IO.inspect("mapping finished")

    GenServer.cast(Bucket, :persist_buffers)

    partition_length = 8

    IO.inspect("reduce start")

    :ok = GenServer.call(master, {:set_job_counter, partition_length})

    Enum.each(0..(partition_length - 1), fn index ->
      GenServer.cast(master, {:reduce_phase, index, nil})
    end)

    receive do
      {:job_done} -> nil
    end

    IO.inspect("reduce end")

    GenServer.call(Bucket, :reset)

    clear_caches()
  end

  defp init_caches(map_lambda, reduce_lambda) do
    Cache.init(:lambdas)
    Cache.init(:splits)
    Cache.insert(:lambdas, :map_lambda, map_lambda)
    Cache.insert(:lambdas, :reduce_lambda, reduce_lambda)
  end

  defp clear_caches() do
    Cache.delete_table(:lambdas)
    Cache.delete_table(:splits)
  end

  def no_overhead_map() do
    anf2 = fn ->
      chunks =
        0..0
        |> Enum.map(fn index ->
          File.stream!("chunks/" <> Integer.to_string(index) <> ".txt")
        end)

      chunks
      |> Enum.flat_map(fn chunk ->
        chunk
        |> Enum.map(fn key ->
          {key, 1}
        end)
      end)
    end

    {timer1, response} = Helper.get_benchmark(anf2)
  end

  def no_overhead() do
    anf = fn ->
      File.stream!(@file_path)
      Stream.flat_map(&String.split(&1, " "))
      |> Enum.reduce(%{}, fn word, acc ->
        Map.update(acc, word, 1, &(&1 + 1))
      end)
    end

    {timer1, _result} = Helper.get_benchmark(anf)
    IO.inspect(timer1)
  end

  def no_overhead_flow() do
    anf = fn ->
      File.stream!(@file_path)
      |> Flow.from_enumerable()
      |> Flow.flat_map(&String.split(&1, " "))
      |> Flow.partition()
      |> Enum.reduce(fn -> %{} end, fn word, acc ->
        Map.update(acc, word, 1, &(&1 + 1))
      end)
    end

    {timer1, _} = Helper.get_benchmark(anf)
    IO.inspect(timer1)
  end
end
