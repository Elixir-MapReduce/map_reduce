defmodule Parser do
  def parse(file_path) do
    {:ok, file} = File.open("parsed_data.txt", [:append])

    _content =
      File.stream!(file_path)
      |> Stream.map(&String.trim/1)
      |> Stream.flat_map(&String.split(&1, " "))
      |> Enum.each(fn word -> IO.binwrite(file, word <> "\n") end)
  end

  def split() do
    File.rm_rf("chunks/")
    File.mkdir("chunks/")

    files =
      0..15
      |> Enum.map(fn index ->
        {:ok, file} = File.open("chunks/" <> Integer.to_string(index) <> ".txt", [:append])
        file
      end)

    File.stream!("parsed_data.txt")
    |> Stream.with_index()
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Enum.reduce(fn -> nil end, fn {chunk, index}, _acc ->
      rem = Integer.mod(index, 16)
      IO.binwrite(Enum.at(files, rem), chunk)
      nil
    end)
  end
end
