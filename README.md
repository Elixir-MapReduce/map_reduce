![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)

# MapReduce
The aim of this project is to implement a distributed, fault-tolerant MapReduce framework using elixir language.

## Usage Guide
First, open the ternimal, go to the application root and then run:
```sh
iex -S mix
```

Then you have to define two functions, `map` and `reduce`, depending on the problem you want to solve:

```elixir
mapper = fn (x) -> nil end # you have to define something instead of nil
reducer = fn (x, y) -> nil end # you have to define something instead of nil
```

Then you can use the MapReduce module to calculate the ansewr for your desired list:
```elixir
MapReduce.solve(list, mapper, reducer)
```

Note that here we used anonymous functions, you can use normal functions but you have to use the syntax `MapReduce.solve(list, &mapper, &reducer)` in that case

## License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.
