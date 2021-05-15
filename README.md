![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)

# MapReduce
The aim of this project is to implement a distributed, fault-tolerant MapReduce framework using elixir language.

## Usage Guide
First, open the ternimal, go to the application root and then run:
```sh
iex -S mix
```

Then you have to define two functions, `map` and `reduce`, depending on the problem you want to solve.
Let's say we want to solve the famous `word count` problem.
Here's how you can define your map & reduce functions:

```elixir
mapper = fn {_document, words} -> Enum.map(words, fn word -> {word, 1} end) end
reducer = fn {word, values} -> {word, Enum.reduce(values, 0, fn x, acc -> x + acc end)} end
```

Then you can use the MapReduce module to calculate the answer for your desired list:
```elixir
list = [{"document_name", ["a", "b", "a", "aa", "a"]}]
MapReduce.solve(list, mapper, reducer) # you should get %{"a" => 3, "aa" => 1, "b" => 1} 
```

Note that here we used anonymous functions, you can use normal functions but you have to use the syntax `MapReduce.solve(list, &mapper, &reducer)` in that case

## License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.
