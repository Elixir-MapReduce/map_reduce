defmodule Helper do
  require SampleDomains

  def get_map_reduce(problem_domain) when is_atom(problem_domain) do
    SampleDomains.map_reduce({problem_domain})
  end

  def get_words(file_path) do
    File.read!(file_path)
    #|> String.replace(~r"[, ; . ? ! \[ \] \) \( \: \" \- ]", " ")
    |> String.trim()
    #|> String.downcase()
    |> String.split()
    #|> String.split(~r/\n| /)
  end

  def get_hash_for({key, _value}) do
    :crypto.hash(:sha, to_string(key)) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  end

  def persist(data) do
    File.write("output.txt", Poison.encode!(data))
  end

  def get_benchmark(function) do
    {time, value} =
      function
      |> :timer.tc()

    {time / 1_000_000, value}
  end
end
