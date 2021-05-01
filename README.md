![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)

# MapReduce
The aim of this project is to implement a distributed, fault-tolerant MapReduce framework using elixir language.

## Usage Guide
First you have to define two functions, `map` and `reduce`, depending on the problem you want to solve. 
For example if you want to calculate the sum of a list of numbers, here's what you have to do:

open the ternimal, go to the application root and then run:
```sh
iex -S mix
```

then write the following code:
```elixir
mapper = &(&1)
reducer = &(&1 + &2)
acc = 0 # acc is the answer for the problem when the list is empty
list = [1,4,5,6,3] # you can change this
MapReduce.main(list, mapper, reducer, acc) # you should get 19 here
```

Note that here we used anonymous functions, you can use normal functions but you have to use the syntax `MapReduce.main(list, &mapper, &reducer, acc)` in that case

## License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.
