![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)

# MapReduce
The aim of this project is to implement a distributed, fault-tolerant MapReduce framework using elixir language.

## Usage Guide
First, open the ternimal, go to the application root and then run:
```sh
iex -S mix
```

Then you have to define two functions, `map` and `reduce`, depending on the problem you want to solve. 
For example if you want to calculate the sum of elements of a list, here's what you have to do:

```elixir
mapper = fn (x) -> x end
reducer = fn (x, y) -> x + y end
acc = 0 # acc is the answer for the problem when the list is empty (here, sum of elements of an empty list is 0)
```

Then you can use the MapReduce module to calculate the ansewr for your desired list:
```elixir
list = [1,4,5,6,3] # you can change this
MapReduce.main(list, mapper, reducer, acc) # you should get 19 here
```

Note that here we used anonymous functions, you can use normal functions but you have to use the syntax `MapReduce.main(list, &mapper, &reducer, acc)` in that case

## License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.
