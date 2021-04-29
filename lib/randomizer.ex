defmodule Randomizer do
  @moduledoc """
  Random string generator module.
  """

  @doc """
  Generate random string based on the given legth. It is also possible to generate certain type of randomise string using the options below:
  * :all - generate alphanumeric random string
  * :alpha - generate nom-numeric random string
  * :numeric - generate numeric random string
  * :upcase - generate upper case non-numeric random string
  * :downcase - generate lower case non-numeric random string
  ## Example
      iex> Iurban.String.randomizer(20) //"Je5QaLj982f0Meb0ZBSK"
  """
  def randomizer(length) do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"

    lists =
      (alphabets <> String.downcase(alphabets) <> numbers)
      |> String.split("", trim: true)

    do_randomizer(length, lists)
  end

  @doc false
  defp get_range(length) when length > 1, do: 1..length
  defp get_range(_length), do: [1]

  @doc false
  defp do_randomizer(length, lists) do
    get_range(length)
    |> Enum.reduce([], fn _, acc -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end

  def randomizer(_length_of_strings, 0, result) do
    result
  end

  def randomizer(length_of_strings, length_of_list) do
    randomizer(length_of_strings, length_of_list, [])
  end

  def randomizer(length_of_strings, length_of_list, result) do
    randomizer(length_of_strings, length_of_list - 1, [randomizer(length_of_strings) | result])
  end
end
