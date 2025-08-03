# MapReduce

![CI](https://github.com/ihaveint/map_reduce/workflows/Elixir%20CI/badge.svg)
[![Hex version badge](https://img.shields.io/badge/Hex-0.2.0-blue)](https://hex.pm/packages/map_reduce)
![Coverage](https://img.shields.io/badge/coverage-98.04%25-green)

A **distributed, fault-tolerant MapReduce framework** implemented in Elixir that enables parallel processing of large datasets across multiple worker processes. This framework provides automatic load balancing, fault tolerance with worker recovery, and seamless scaling for compute-intensive tasks.

## ✨ Key Features

- **🔄 Distributed Processing**: Automatically distributes work across configurable number of worker processes
- **🛡️ Fault Tolerance**: Built-in worker monitoring with automatic failure detection and recovery
- **⚖️ Load Balancing**: Intelligent hash-based work distribution ensures even load across workers
- **📈 Scalable**: Supports processing of large datasets by chunking and parallel execution
- **🔍 Real-time Monitoring**: Heartbeat monitoring system detects network congestion and worker failures
- **🏗️ Production Ready**: Includes comprehensive test coverage (98%+) and CI/CD pipeline

## 🏛️ Architecture

The framework consists of several key components:

- **MapReduce Module**: Main API interface for job submission
- **Scheduler**: Orchestrates job distribution and manages worker lifecycle
- **Worker Processes**: Execute map/reduce functions on data partitions
- **Monitor**: Provides fault detection through process monitoring and heartbeat checks
- **Job System**: Manages job state and results collection

## 📦 Installation

This project is [available in Hex](https://hex.pm/packages/map_reduce), and can be installed by adding `map_reduce` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:map_reduce, "~> 0.2.0"}
  ]
end
```

## 🚀 Quick Start

### Basic Word Count Example

```elixir
# Define your map and reduce functions
mapper = fn {_document, words} -> Enum.map(words, fn word -> {word, 1} end) end
reducer = fn {word, values} -> {word, Enum.reduce(values, 0, fn x, acc -> x + acc end)} end

# Process your data
list = [{"document_name", ["a", "b", "a", "aa", "a"]}]
result = MapReduce.solve(list, mapper, reducer)
# Returns: %{"a" => 3, "aa" => 1, "b" => 1}
```

### Multi-Document Processing

```elixir
collection = [
  {"document1", ["harry", "potter", "sam", "harry", "jack"]},
  {"document2", ["jack", "potter", "harry", "daniel"]}
]

result = MapReduce.solve(collection, mapper, reducer, 10)
# Returns: %{"daniel" => 1, "harry" => 3, "jack" => 2, "potter" => 2, "sam" => 1}
```

## 📚 API Reference

### Core Functions

#### `MapReduce.solve/3`
```elixir
MapReduce.solve(collection, map_function, reduce_function)
```
Processes data using default worker count (10,000 processes).

#### `MapReduce.solve/4`
```elixir
MapReduce.solve(collection, map_function, reduce_function, process_count)
```
Processes data with specified number of worker processes.

**Parameters:**
- `collection`: List of `{key, data}` tuples to process
- `map_function`: Function that transforms input data into key-value pairs
- `reduce_function`: Function that aggregates values for each key
- `process_count`: Number of worker processes to spawn (optional, defaults to 10,000)

**Function Syntax:**
- **Anonymous functions**: Use as shown in examples above
- **Named functions**: Use capture syntax: `MapReduce.solve(list, &mapper/1, &reducer/1)`

## 🎯 Use Cases & Examples

### 1. Large-Scale Word Counting
Perfect for analyzing large text corpora, log files, or document collections:

```elixir
# Process large text files efficiently
words = Helper.get_words("large_document.txt")
chunks = Enum.chunk_every(words, 3000)

collection = chunks
|> Enum.with_index()
|> Enum.map(fn {chunk, idx} -> {"chunk_#{idx}", chunk} end)

{mapper, reducer} = Helper.get_map_reduce(:word_count)
result = MapReduce.solve(collection, mapper, reducer, 50)
```

### 2. Page Rank / Link Analysis
Analyze relationships and connections in graph data:

```elixir
# Analyze page links or social connections
connections = [{1, [3]}, {2, [3]}, {4, [5]}, {5, [6]}]

link_mapper = fn {source, targets} -> 
  Enum.map(targets, fn target -> {target, source} end) 
end

link_reducer = fn {key, values} -> 
  {key, Enum.reduce(values, [], fn x, acc -> [x | acc] end)} 
end

result = MapReduce.solve(connections, link_mapper, link_reducer)
# Returns: %{3 => [1, 2], 5 => [4], 6 => [5]}
```

### 3. Custom Data Processing
The framework is flexible enough for various data processing tasks:

```elixir
# Example: Sales data aggregation
sales_data = [
  {"Q1", [{"product_A", 100}, {"product_B", 150}]},
  {"Q2", [{"product_A", 200}, {"product_B", 120}]}
]

sales_mapper = fn {_quarter, sales} -> sales end
sales_reducer = fn {product, amounts} -> 
  {product, Enum.sum(amounts)} 
end

total_sales = MapReduce.solve(sales_data, sales_mapper, sales_reducer)
```

## 🛠️ Built-in Problem Domains

The framework includes pre-built solutions for common problems:

```elixir
# Word counting
{mapper, reducer} = Helper.get_map_reduce(:word_count)

# Page rank analysis  
{mapper, reducer} = Helper.get_map_reduce(:page_rank)
```

## ⚙️ Configuration & Performance

### Worker Process Tuning
- **Small datasets**: Use fewer workers (1-10) to reduce overhead
- **Large datasets**: Scale up to thousands of workers for maximum parallelism
- **Default**: 10,000 workers provides good balance for most use cases

### Fault Tolerance Settings
The framework includes built-in resilience features:
- Worker failure simulation rate: 3% (configurable)
- Network congestion simulation: 3% (configurable)
- Automatic worker replacement on failure
- Heartbeat monitoring every 500ms

## 🧪 Testing

Run the comprehensive test suite:

```bash
mix test
```

The framework includes tests for:
- Basic MapReduce operations
- Multi-document processing
- Large-scale data processing
- Fault tolerance scenarios
- Data structure integrity

## 🏗️ Development

### Prerequisites
- Elixir ~> 1.12.0
- OTP 24.0+

### Setup
```bash
git clone https://github.com/Elixir-MapReduce/map_reduce.git
cd map_reduce
mix deps.get
mix test
```

### Building Documentation
```bash
mix docs
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Make sure to:
- Add tests for new functionality
- Update documentation as needed
- Follow existing code style conventions

## 📄 License

The source code is released under MIT License.

Check [LICENSE](LICENSE) for more information.

---

**Built with ❤️ in Elixir** | Leveraging the Actor Model for distributed, fault-tolerant computing
