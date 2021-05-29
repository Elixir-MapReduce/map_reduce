defmodule Submission do
  require Job

  defstruct(
    job: %Job{},
    result: nil,
    worker_pid: nil
  )
end
