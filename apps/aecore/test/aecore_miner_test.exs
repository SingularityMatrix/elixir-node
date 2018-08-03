defmodule MinerTest do
  use ExUnit.Case

  alias Aecore.Persistence.Worker, as: Persistence
  alias Aecore.Chain.Worker, as: Chain
  alias Aecore.Miner.Worker, as: Miner
  alias Aecore.Keys.Worker, as: Keys

  setup do
    on_exit(fn ->
      Persistence.delete_all_blocks()
      :ok
    end)
  end

  @tag timeout: 20_000
  @tag :miner
  test "mine_next_block" do
    Miner.mine_sync_block_to_chain()
    assert Chain.top_height() >= 1
    assert Chain.top_block().header.height >= 1
    assert length(Chain.longest_blocks_chain()) > 1
    assert Chain.top_block().header.miner == Keys.sign_pubkey()
  end
end
