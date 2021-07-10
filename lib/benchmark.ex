defmodule Benchmark do
  def run() do
    Benchee.run(
      %{
        # "sequential" => fn -> MapReduce.run(:file, "yelp_academic_dataset_review.json") end,
        "input1" => fn -> MapReduce.no_overhead("input1.txt") end,
        "input2" => fn -> MapReduce.no_overhead("input2.txt") end,
        "input3" => fn -> MapReduce.no_overhead("input3.txt") end,
        "input4" => fn -> MapReduce.no_overhead("input4.txt") end
        # "input5" => fn -> MapReduce.run(:file,"input5.txt") end,
        # "input6" => fn -> MapReduce.run(:file,"input6.txt") end,
        # "input1" => fn -> MapReduce.run(:file, "input1.txt") end,
        # "input2" => fn -> MapReduce.run(:file, "input2.txt") end,
        # "input3" => fn -> MapReduce.run(:file, "input3.txt") end,
        # "input4" => fn -> MapReduce.run(:file, "input4.txt") end
        # "input5" => fn -> MapReduce.run(:file,"input5.txt") end,
        # "input6" => fn -> MapReduce.run(:file,"input6.txt") end,
        # "input7" => fn -> MapReduce.run(:file,"input7.txt") end,
        # "input8" => fn -> MapReduce.run(:file,"input8.txt") end,
      },
      parallel: 1,
      formatters: [
        {Benchee.Formatters.HTML, file: "samples_output/my.html"}
        # {Benchee.Formatters.Console, extended_statistics: true}
      ]
    )

    :ok
  end
end
