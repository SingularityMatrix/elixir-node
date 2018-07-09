defmodule AecoreCuckooTest do
  @moduledoc """
  Unit tests for the cuckoo module
  """

  require Logger

  use ExUnit.Case

  alias Aecore.Persistence.Worker, as: Persistence
  alias Aecore.Pow.Cuckoo
  alias Aecore.Chain.Block
  alias Aecore.Chain.Header
  alias Aecore.Tx.SignedTx
  alias Aecore.Tx.DataTx
  alias Aecore.Account.Tx.SpendTx

  setup do
    on_exit(fn ->
      Persistence.delete_all_blocks()
      :ok
    end)
  end

  @tag timeout: 60000
  @tag :cuckoo
  test "Generate solution with a winning nonce and high target threshold", setup do
    %{pow_evidence: found_solution} = Cuckoo.generate(block_candidate().header)
    assert found_solution == wining_solution()
  end

  @tag timeout: 60000
  @tag :cuckoo
  test "Verify solution with a high target threshold", setup do
    header = Cuckoo.generate(block_candidate().header)
    assert true == Cuckoo.verify(header)
  end

  defp wining_solution do
    [
      16,
      1900,
      2342,
      2865,
      4474,
      5395,
      7328,
      7797,
      8750,
      9149,
      9590,
      10293,
      11413,
      11471,
      12320,
      12875,
      12885,
      14599,
      14779,
      15204,
      15531,
      16750,
      16843,
      18449,
      18562,
      18904,
      19599,
      19988,
      20686,
      21807,
      23437,
      23788,
      24989,
      26006,
      27427,
      27679,
      28421,
      28605,
      29687,
      30388,
      31001,
      31655
    ]
  end

  defp block_candidate do
    root_hash =
      <<3, 182, 90, 114, 176, 76, 149, 119, 61, 31, 182, 67, 236, 226, 55, 252, 162, 181, 135, 38,
        5, 100, 44, 42, 98, 30, 168, 89, 51, 12, 94, 36>>

    prev_hash =
      <<12, 191, 206, 141, 4, 69, 187, 23, 135, 251, 168, 240, 201, 114, 223, 101, 113, 237, 36,
        91, 38, 191, 166, 21, 145, 170, 182, 194, 136, 25, 12, 248>>

    txs_hash =
      <<34, 12, 151, 127, 24, 49, 178, 171, 232, 129, 182, 150, 150, 82, 125, 117, 238, 56, 140,
        96, 82, 104, 183, 188, 198, 161, 158, 118, 132, 90, 208, 8>>

    miner =
      <<3, 238, 194, 37, 53, 17, 131, 41, 32, 167, 209, 197, 236, 138, 35, 63, 33, 4, 236, 181,
        172, 160, 156, 141, 129, 143, 104, 133, 128, 109, 199, 73, 102>>

    %Block{
      header: %Header{
        height: 5,
        nonce: 161,
        pow_evidence: List.duplicate(0, 42),
        prev_hash: prev_hash,
        root_hash: root_hash,
        target: 553_713_663,
        time: 1_523_540_274_221,
        txs_hash: txs_hash,
        miner: miner,
        version: 1
      },
      txs: []
    }
  end
end
