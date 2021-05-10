![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)

# MapReduce
The aim of this project is to implement a distributed, fault-tolerant MapReduce framework using elixir language.

## Usage Guide
First, open the ternimal, go to the application root and then run:
```sh
iex -S mix
```

Then you have to define two functions, `map` and `reduce`, depending on the problem you want to solve.
Let's say you have a list of connections in the format {source, target} and you want to calculate for each node the list of
sources that have connections to it. Here's how you can define your map & reduce functions:

```elixir
fn mapper {source, target} -> %{target => [source]} end
fn reducer a,b -> %{get_key(a) => Enum.concat(get_value(a), get_value(b))} end
```

`note`: `get_key` and `get_value` are two functions that assume the given input is a map with only one key and value, the return that key or value.

Then you can use the MapReduce module to calculate the ansewr for your desired list:
```elixir
list = [{1, 3}, {2, 3}, {4, 5}, {5, 6}]
MapReduce.solve(list, mapper, reducer) # you should get %{3 => [1, 2], 5 => [4], 6 => [5]} in this scenario 
```

Note that here we used anonymous functions, you can use normal functions but you have to use the syntax `MapReduce.solve(list, &mapper, &reducer)` in that case

## License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.
