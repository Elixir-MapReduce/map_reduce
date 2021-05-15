defmodule Submission do
  require Job

  defstruct(
    job: %Job{},
    worker_pid: nil
  )
end
