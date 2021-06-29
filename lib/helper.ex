defmodule Helper do
  @regex_split " "

  def get_benchmark(function) do
    {time, value} =
      function
      |> :timer.tc()

    {time / 1_000_000, value}
  end

  #def get_hash_for_key(key) when is_bitstring(key) == false do
    #:crypto.hash(:sha, to_string(key)) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  #end
  
  def get_hash_for_key(key) do
    :crypto.hash(:sha, to_string(key)) |> Base.encode16() |> Integer.parse(16) |> elem(0)
    #String.length(key)
  end

  def get_words(file_path) do
    File.read!(file_path)
    |> String.trim()
    |> String.split(@regex_split)

    # File.stream!(file_path)
    # |> Enum.map(&String.trim/1)
    # |> Enum.map(&String.split(&1, @regex_split))
  end

  def get_words_stream(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim/1)
    |> Stream.flat_map(&String.split(&1, @regex_split))
  end

  def get_cores_count() do
    16
  end
end
