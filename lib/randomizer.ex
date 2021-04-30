defmodule Randomizer do
  def randomizer(length) do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"

    lists =
      (alphabets <> String.downcase(alphabets) <> numbers)
      |> String.split("", trim: true)

    do_randomizer(length, lists)
  end

  def randomizer(length_of_strings, length_of_list) do
    randomizer(length_of_strings, length_of_list, [])
  end

  def randomizer(_length_of_strings, 0, result) do
    result
  end

  def randomizer(length_of_strings, length_of_list, result) do
    randomizer(length_of_strings, length_of_list - 1, [randomizer(length_of_strings) | result])
  end

  defp get_range(length) when length > 1, do: 1..length
  defp get_range(_length), do: [1]

  defp do_randomizer(length, lists) do
    get_range(length)
    |> Enum.reduce([], fn _, acc -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end
end
