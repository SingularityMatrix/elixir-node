defmodule Aeutil.MultiNodeTestFramework do

  alias Porcelain

  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  def new_node(port) do
    GenServer.call(__MODULE__, {:new_node, port})
  end

  def alive_processes() do
    GenServer.call(__MODULE__, {:alive_processes})
  end

  def run_nodes_test() do
    GenServer.cast(__MODULE__, {:run_nodes_test})
  end

  def handle_call({:get_state}, _, state) do
    {:reply, state, state}
  end

  def handle_cast({:run_nodes_test}, state) do
    for {k, v} <- state, do: System.cmd "mix", ["test"], cd: v.path
    {:no_reply, :ok, state}
  end

  def handle_call({:alive_processes}, _, state) do
    alive_processes = for {name, pid} <- state, into: %{}, do: {name, Process.alive?(pid)}
    {:reply, alive_processes, state}
  end

  def handle_call({:new_node, port}, _, state) do
    new_node_num = Enum.count(state) + 1 |> to_string()
    name = "node" <> new_node_num
    {:ok, tmp_path} = Temp.mkdir name
    System.cmd("cp", ["-R", System.cwd, tmp_path])
    tmp_path = tmp_path <> "/elixir-node"
    System.cmd("sed", [
      "-i",
      "s/4000/#{port}/",
      Path.join(tmp_path, "apps/aehttpserver/config/dev.exs")
    ])

    System.cmd("sed", [
      "-i",
      "s/4000/#{port}/",
      Path.join(tmp_path, "apps/aehttpserver/config/test.exs")
    ])

    new_state = Map.put(state, name, %{port: port, path: tmp_path})
    # %{pid: pid} = Porcelain.spawn_shell("iex -S mix phx.server", in: :receive, out: {:send, self()}, dir: tmp_path)
    {:reply, new_state, new_state}
  end
end
