defmodule Aecore.Persistence.Worker.Supervisor do
  use Supervisor

  ## Ensures that the worker will be shutdown in 30 seconds
  @max_shutdown_time 30_000

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Aecore.Persistence.Worker, [], shutdown: @max_shutdown_time)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
