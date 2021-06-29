defmodule Input do
  def from(:file, file_path) do
    [Helper.get_words_stream(file_path)]
  end

  def from(:chunks, chunk_folder, number_of_chunks) do
    _chunks =
      0..(number_of_chunks - 1)
      |> Enum.map(fn index ->
        File.stream!(chunk_folder <> Integer.to_string(index) <> ".txt")
      end)
  end
end
