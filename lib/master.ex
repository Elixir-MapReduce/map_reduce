defmodule Master do
  use GenServer

  @impl true
  def init([worker_cnt, splits_count, caller]) do
    {:ok,
     %{
       worker_pool:
         Enum.map(1..worker_cnt, fn _index ->
           GenServer.start_link(Worker, [self()]) |> elem(1)
         end),
       remaining_jobs: splits_count,
       caller: caller,
       queue: [],
       current_id: 0
     }}
  end

  # def start_link(_) do
  # GenServer.start_link(__MODULE__, nil)
  # end

  def execute_or_put_in_queue(op_atom, name_in_cache, bool, pool, queue) do
    new_pool = execute(!bool, op_atom, name_in_cache, pool)
    new_queue = put_in_queue(bool, op_atom, name_in_cache, queue)
    {new_queue, new_pool}
  end

  def execute(false, _, _, pool) do
    pool
  end

  def execute(true, op_atom, name_in_cache, [head | tail] = _pool) do
    GenServer.cast(head, {op_atom, name_in_cache})
    tail
  end

  def put_in_queue(false, _, _, queue) do
    queue
  end

  def put_in_queue(_true, op_atom, name_in_cache, queue) do
    _queue = [{op_atom, name_in_cache} | queue]
  end

  @impl true
  def handle_info(
        {:job_done, _response, worker_pid},
        %{remaining_jobs: remaining_jobs, queue: queue, worker_pool: pool, caller: caller} = state
      ) do
    if remaining_jobs == 1 do
      # IO.puts("job done signal received in master")
      send(caller, {:job_done})
    end

    pool = [worker_pid | pool]

    if !Enum.empty?(queue) do
      {op_atom, first_element_in_queue} = hd(queue)
      [_ | queue] = queue
      pool = execute(true, op_atom, first_element_in_queue, pool)
      {:noreply, %{state | remaining_jobs: remaining_jobs - 1, worker_pool: pool, queue: queue}}
    else
      {:noreply, %{state | remaining_jobs: remaining_jobs - 1, worker_pool: pool}}
    end
  end

  @impl true
  def handle_cast({:map_phase, name_in_cache, _id}, %{worker_pool: pool, queue: queue} = state) do
    {queue, pool} = execute_or_put_in_queue(:map, name_in_cache, Enum.empty?(pool), pool, queue)
    {:noreply, %{state | worker_pool: pool, queue: queue}}
  end

  @impl true
  def handle_cast({:reduce_phase, name_in_cache, _id}, %{worker_pool: pool, queue: queue} = state) do
    {queue, pool} =
      execute_or_put_in_queue(:reduce, name_in_cache, Enum.empty?(pool), pool, queue)

    {:noreply, %{state | worker_pool: pool, queue: queue}}
  end

  @impl true
  def handle_call({:set_job_counter, counter}, _from, state) do
    remaining_jobs = counter
    {:reply, :ok, %{state | remaining_jobs: remaining_jobs}}
  end
end
