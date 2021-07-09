defmodule Benchmark do
  def run() do
    Benchee.run(
      %{
        # "sequential" => fn -> MapReduce.run(:file, "yelp_academic_dataset_review.json") end,
        "input1" => fn -> MapReduce.no_overhead_flow("input1.txt") end,
        "input2" => fn -> MapReduce.no_overhead_flow("input2.txt") end,
        "input3" => fn -> MapReduce.no_overhead_flow("input3.txt") end,
        "input4" => fn -> MapReduce.no_overhead_flow("input4.txt") end,

      },
      parallel: 1,
      formatters: [
        {Benchee.Formatters.HTML, file: "samples_output/my.html"},
        # {Benchee.Formatters.Console, extended_statistics: true}
      ]
    )

    :ok
  end
end
