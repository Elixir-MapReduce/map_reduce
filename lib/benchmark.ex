defmodule Benchmark do
  def run() do
    Benchee.run(
      %{
        "sequential" => fn -> MapReduce.run(:file, "yelp_academic_dataset_review.json") end,
        "parallel" => fn -> MapReduce.run(:chunks, "chunks/", 16) end
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
