defmodule ETS.Cache do
  def init(table) do
    :ets.new(table, [:public, :named_table, read_concurrency: true, write_concurrency: true])
  end

  def insert(table, key, value) do
    :ets.insert(table, {key, value})
  end

  def lookup(table, key) do
    case :ets.lookup(table, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end

  def delete_table(table) do
    :ets.delete(table)
  end
end
