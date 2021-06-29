defmodule Benchmark do
  def run() do
    Benchee.run(
      %{
        "sequential" => fn -> MapReduce.no_overhead() end,
        "parallel" => fn -> MapReduce.run() end
      },
      parallel: 1,
      formatters: [
        {Benchee.Formatters.HTML, file: "samples_output/my.html"},
        {Benchee.Formatters.Console, extended_statistics: true}
      ]
    )

    :ok
  end
end
