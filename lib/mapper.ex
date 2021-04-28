defmodule Mapper do
	require Reducer

	def start_link do
		Task.start_link(fn -> loop([], [], []) end) 
	end

	defp loop(map_lambda, raw, reduce_lambda) do
		receive do
			{:add_raw_element, value} -> loop(map_lambda, [value | raw], reduce_lambda)
			{:set_raw_array, values} -> loop(map_lambda, values, reduce_lambda)
			{:calc} -> apply_map(map_lambda, raw, reduce_lambda)
			{:set_map_reduce, map_lambda, reduce_lambda} -> loop(map_lambda, raw, reduce_lambda)
		end
	end

	defp apply_map(map_lambda, raw, reduce_lambda) do
		IO.puts(["raw list is ", Enum.join(raw, ",")])                             
		apply_map(map_lambda, raw, [], reduce_lambda)
	end

	defp apply_map(_map_lambda, [], result, reduce_lambda) do
		# {:ok, file} = File.open(Path.join("test", "output.txt"), [:write])
		IO.puts(["result before reduce is ",  result |> Enum.reverse |> Enum.join(",")])                             

		final_result = Reducer.reduce(result |> Enum.reverse, reduce_lambda)

		IO.puts("final result: #{final_result}")
		# IO.puts(final_result)

		# for value <- result do
	        # IO.puts value
	        # IO.write(file, value <> ~s(\n))
      	# end    
      	# File.close(file)
      	# Process.exit(self(), :kill)
	end

	defp apply_map(map_lambda, [h | t], result, reduce_lambda) do
		apply_map(map_lambda, t , [map_lambda.(h) | result], reduce_lambda)		
	end
end