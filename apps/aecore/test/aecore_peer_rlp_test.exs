defmodule AecorePeerRLPTest do
  use ExUnit.Case

  alias Aecore.Peers.PeerConnection
  alias Aecore.Chain.Identifier

  test "encode and decode RLP test based on epoch binaries" do
    # ping
    assert PeerConnection.rlp_encode(1, ping_object()) == ping_binary()
    assert PeerConnection.rlp_decode(1, ping_binary()) == ping_object()

    # get_header_by_hash
    assert PeerConnection.rlp_encode(3, get_block_and_header_by_hash_object()) ==
             get_block_and_header_by_hash_binary()

    assert PeerConnection.rlp_decode(3, get_block_and_header_by_hash_binary()) ==
             get_block_and_header_by_hash_object()

    # get_n_successors
    assert PeerConnection.rlp_encode(5, get_n_successors_object()) == get_n_successors_binary()

    assert PeerConnection.rlp_decode(5, get_n_successors_binary()) == get_n_successors_object()

    # get_block
    assert PeerConnection.rlp_encode(7, get_block_and_header_by_hash_object()) ==
             get_block_and_header_by_hash_binary()

    assert PeerConnection.rlp_decode(7, get_block_and_header_by_hash_binary()) ==
             get_block_and_header_by_hash_object()

    # get_header_by_height
    assert PeerConnection.rlp_encode(15, get_header_by_height_object()) ==
             get_header_by_height_binary()

    assert PeerConnection.rlp_decode(15, get_header_by_height_binary()) ==
             get_header_by_height_object()

    # header_hashes response
    assert PeerConnection.rlp_encode(100, header_hashes_response_object()) ==
             header_hashes_response_binary()

    assert PeerConnection.rlp_decode(100, header_hashes_response_binary()) ==
             header_hashes_response_decoded()

    # header response
    assert PeerConnection.rlp_encode(100, header_response_object()) == header_response_binary()

    assert PeerConnection.rlp_decode(100, header_response_binary()) == %{
             header_response_object()
             | object: %{header: header_response_object().object}
           }

    # block response
    assert PeerConnection.rlp_encode(100, block_response_object()) == block_response_binary()

    assert PeerConnection.rlp_decode(100, block_response_binary()) == %{
             block_response_object()
             | object: %{block: block_response_object().object}
           }

    # mempool response
    assert PeerConnection.rlp_encode(100, mempool_response_object()) == mempool_response_binary()

    assert PeerConnection.rlp_decode(100, mempool_response_binary()) == mempool_response_object()
  end

  def ping_object do
    %{
      best_hash:
        <<254, 17, 240, 34, 119, 165, 230, 98, 79, 102, 52, 13, 100, 213, 41, 139, 25, 111, 250,
          78, 94, 33, 20, 202, 237, 162, 77, 160, 205, 159, 30, 146>>,
      difficulty: 190.0362341,
      genesis_hash:
        <<254, 17, 240, 34, 119, 165, 230, 98, 79, 102, 52, 13, 100, 213, 41, 139, 25, 111, 250,
          78, 94, 33, 20, 202, 237, 162, 77, 160, 205, 159, 30, 146>>,
      peers: [
        %{
          host: '31.13.249.70',
          port: 3015,
          pubkey:
            <<225, 20, 115, 180, 23, 84, 149, 52, 111, 153, 254, 213, 39, 210, 49, 196, 30, 21, 9,
              93, 48, 103, 84, 63, 207, 94, 95, 41, 134, 145, 215, 123>>
        }
      ],
      port: 3015,
      share: 32
    }
  end

  def ping_binary do
    <<248, 150, 1, 130, 11, 199, 32, 160, 254, 17, 240, 34, 119, 165, 230, 98, 79, 102, 52, 13,
      100, 213, 41, 139, 25, 111, 250, 78, 94, 33, 20, 202, 237, 162, 77, 160, 205, 159, 30, 146,
      154, 49, 46, 57, 48, 48, 51, 54, 50, 51, 52, 49, 48, 48, 48, 48, 48, 48, 48, 49, 52, 57, 48,
      101, 43, 48, 50, 160, 254, 17, 240, 34, 119, 165, 230, 98, 79, 102, 52, 13, 100, 213, 41,
      139, 25, 111, 250, 78, 94, 33, 20, 202, 237, 162, 77, 160, 205, 159, 30, 146, 243, 178, 241,
      140, 51, 49, 46, 49, 51, 46, 50, 52, 57, 46, 55, 48, 130, 11, 199, 160, 225, 20, 115, 180,
      23, 84, 149, 52, 111, 153, 254, 213, 39, 210, 49, 196, 30, 21, 9, 93, 48, 103, 84, 63, 207,
      94, 95, 41, 134, 145, 215, 123>>
  end

  def get_block_and_header_by_hash_object do
    %{
      hash:
        <<138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231, 228, 25, 248, 145, 174, 249, 194,
          130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118, 78>>
    }
  end

  def get_block_and_header_by_hash_binary do
    <<226, 1, 160, 138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231, 228, 25, 248, 145, 174, 249,
      194, 130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118, 78>>
  end

  def get_header_by_height_object do
    %{height: 5}
  end

  def get_header_by_height_binary do
    <<194, 1, 5>>
  end

  def get_n_successors_object do
    %{
      hash:
        <<138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231, 228, 25, 248, 145, 174, 249, 194,
          130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118, 78>>,
      n: 5
    }
  end

  def get_n_successors_binary do
    <<227, 1, 160, 138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231, 228, 25, 248, 145, 174, 249,
      194, 130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118, 78, 5>>
  end

  def header_hashes_response_object do
    %{
      object: [
        <<138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231, 228, 25, 248, 145, 174, 249, 194,
          130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118, 78>>
      ],
      reason: nil,
      result: true,
      type: 6
    }
  end

  def header_hashes_response_binary do
    <<233, 1, 1, 6, 128, 164, 227, 1, 225, 160, 138, 11, 233, 125, 181, 144, 59, 74, 102, 52, 231,
      228, 25, 248, 145, 174, 249, 194, 130, 12, 231, 24, 149, 234, 95, 143, 94, 11, 124, 6, 118,
      78>>
  end

  def header_hashes_response_decoded do
    %{
      object: %{
        hashes: [
          %{
            hash:
              <<102, 52, 231, 228, 25, 248, 145, 174, 249, 194, 130, 12, 231, 24, 149, 234, 95,
                143, 94, 11, 124, 6, 118, 78>>,
            height: 9_947_300_928_104_184_650
          }
        ]
      },
      reason: nil,
      result: true,
      type: 6
    }
  end

  def header_response_object do
    %{
      object: %Aecore.Chain.Header{
        height: 10,
        miner:
          <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193, 150, 109,
            175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>,
        nonce: 96,
        pow_evidence: [
          246,
          875,
          902,
          924,
          1115,
          1406,
          1996,
          2592,
          3998,
          4016,
          5343,
          5905,
          6215,
          6479,
          7687,
          10_185,
          10_342,
          10_945,
          12_223,
          12_503,
          13_758,
          14_051,
          14_245,
          15_175,
          16_383,
          17_123,
          17_892,
          17_959,
          22_032,
          22_445,
          23_273,
          24_807,
          25_091,
          25_340,
          25_609,
          26_298,
          27_287,
          27_366,
          27_615,
          29_855,
          29_951,
          29_958
        ],
        prev_hash:
          <<231, 232, 101, 39, 40, 66, 54, 248, 211, 183, 83, 46, 213, 177, 186, 105, 208, 81, 40,
            163, 62, 24, 149, 129, 28, 131, 122, 10, 178, 29, 147, 109>>,
        root_hash:
          <<139, 73, 72, 45, 47, 44, 86, 20, 145, 225, 243, 45, 48, 48, 88, 251, 72, 199, 163,
            130, 136, 109, 190, 181, 142, 125, 111, 203, 242, 116, 245, 63>>,
        target: 553_713_663,
        time: 1_531_213_372_842,
        txs_hash:
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0>>,
        version: 14
      },
      reason: nil,
      result: true,
      type: 4
    }
  end

  def header_response_binary do
    <<249, 1, 95, 1, 1, 4, 128, 185, 1, 88, 249, 1, 85, 1, 185, 1, 81, 0, 0, 0, 0, 0, 0, 0, 14, 0,
      0, 0, 0, 0, 0, 0, 10, 231, 232, 101, 39, 40, 66, 54, 248, 211, 183, 83, 46, 213, 177, 186,
      105, 208, 81, 40, 163, 62, 24, 149, 129, 28, 131, 122, 10, 178, 29, 147, 109, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 139, 73,
      72, 45, 47, 44, 86, 20, 145, 225, 243, 45, 48, 48, 88, 251, 72, 199, 163, 130, 136, 109,
      190, 181, 142, 125, 111, 203, 242, 116, 245, 63, 0, 0, 0, 0, 33, 0, 255, 255, 0, 0, 0, 246,
      0, 0, 3, 107, 0, 0, 3, 134, 0, 0, 3, 156, 0, 0, 4, 91, 0, 0, 5, 126, 0, 0, 7, 204, 0, 0, 10,
      32, 0, 0, 15, 158, 0, 0, 15, 176, 0, 0, 20, 223, 0, 0, 23, 17, 0, 0, 24, 71, 0, 0, 25, 79,
      0, 0, 30, 7, 0, 0, 39, 201, 0, 0, 40, 102, 0, 0, 42, 193, 0, 0, 47, 191, 0, 0, 48, 215, 0,
      0, 53, 190, 0, 0, 54, 227, 0, 0, 55, 165, 0, 0, 59, 71, 0, 0, 63, 255, 0, 0, 66, 227, 0, 0,
      69, 228, 0, 0, 70, 39, 0, 0, 86, 16, 0, 0, 87, 173, 0, 0, 90, 233, 0, 0, 96, 231, 0, 0, 98,
      3, 0, 0, 98, 252, 0, 0, 100, 9, 0, 0, 102, 186, 0, 0, 106, 151, 0, 0, 106, 230, 0, 0, 107,
      223, 0, 0, 116, 159, 0, 0, 116, 255, 0, 0, 117, 6, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 1, 100,
      131, 109, 221, 170, 3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237,
      193, 150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
  end

  def block_response_object do
    %{
      object: %Aecore.Chain.Block{
        header: %Aecore.Chain.Header{
          height: 10,
          miner:
            <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193, 150,
              109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>,
          nonce: 96,
          pow_evidence: [
            246,
            875,
            902,
            924,
            1115,
            1406,
            1996,
            2592,
            3998,
            4016,
            5343,
            5905,
            6215,
            6479,
            7687,
            10_185,
            10_342,
            10_945,
            12_223,
            12_503,
            13_758,
            14_051,
            14_245,
            15_175,
            16_383,
            17_123,
            17_892,
            17_959,
            22_032,
            22_445,
            23_273,
            24_807,
            25_091,
            25_340,
            25_609,
            26_298,
            27_287,
            27_366,
            27_615,
            29_855,
            29_951,
            29_958
          ],
          prev_hash:
            <<231, 232, 101, 39, 40, 66, 54, 248, 211, 183, 83, 46, 213, 177, 186, 105, 208, 81,
              40, 163, 62, 24, 149, 129, 28, 131, 122, 10, 178, 29, 147, 109>>,
          root_hash:
            <<139, 73, 72, 45, 47, 44, 86, 20, 145, 225, 243, 45, 48, 48, 88, 251, 72, 199, 163,
              130, 136, 109, 190, 181, 142, 125, 111, 203, 242, 116, 245, 63>>,
          target: 553_713_663,
          time: 1_531_213_372_842,
          txs_hash:
            <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0>>,
          version: 14
        },
        txs: []
      },
      reason: nil,
      result: true,
      type: 11
    }
  end

  def block_response_binary do
    <<249, 1, 104, 1, 1, 11, 128, 185, 1, 97, 249, 1, 94, 1, 185, 1, 90, 249, 1, 87, 100, 14, 185,
      1, 81, 0, 0, 0, 0, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 10, 231, 232, 101, 39, 40, 66, 54, 248,
      211, 183, 83, 46, 213, 177, 186, 105, 208, 81, 40, 163, 62, 24, 149, 129, 28, 131, 122, 10,
      178, 29, 147, 109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 139, 73, 72, 45, 47, 44, 86, 20, 145, 225, 243, 45, 48, 48, 88, 251,
      72, 199, 163, 130, 136, 109, 190, 181, 142, 125, 111, 203, 242, 116, 245, 63, 0, 0, 0, 0,
      33, 0, 255, 255, 0, 0, 0, 246, 0, 0, 3, 107, 0, 0, 3, 134, 0, 0, 3, 156, 0, 0, 4, 91, 0, 0,
      5, 126, 0, 0, 7, 204, 0, 0, 10, 32, 0, 0, 15, 158, 0, 0, 15, 176, 0, 0, 20, 223, 0, 0, 23,
      17, 0, 0, 24, 71, 0, 0, 25, 79, 0, 0, 30, 7, 0, 0, 39, 201, 0, 0, 40, 102, 0, 0, 42, 193, 0,
      0, 47, 191, 0, 0, 48, 215, 0, 0, 53, 190, 0, 0, 54, 227, 0, 0, 55, 165, 0, 0, 59, 71, 0, 0,
      63, 255, 0, 0, 66, 227, 0, 0, 69, 228, 0, 0, 70, 39, 0, 0, 86, 16, 0, 0, 87, 173, 0, 0, 90,
      233, 0, 0, 96, 231, 0, 0, 98, 3, 0, 0, 98, 252, 0, 0, 100, 9, 0, 0, 102, 186, 0, 0, 106,
      151, 0, 0, 106, 230, 0, 0, 107, 223, 0, 0, 116, 159, 0, 0, 116, 255, 0, 0, 117, 6, 0, 0, 0,
      0, 0, 0, 0, 96, 0, 0, 1, 100, 131, 109, 221, 170, 3, 238, 153, 246, 48, 67, 139, 193, 171,
      24, 113, 29, 106, 32, 18, 237, 193, 150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55,
      25, 74, 133, 154, 192>>
  end

  def mempool_response_object do
    %{
      object: %{
        txs: [
          %Aecore.Tx.SignedTx{
            data: %Aecore.Tx.DataTx{
              fee: 12,
              nonce: 1,
              payload: %Aecore.Account.Tx.SpendTx{
                amount: 10,
                payload: "",
                receiver: %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                },
                version: 1
              },
              senders: [
                %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                }
              ],
              ttl: 0,
              type: Aecore.Account.Tx.SpendTx
            },
            signatures: [
              <<48, 69, 2, 33, 0, 238, 28, 94, 28, 181, 175, 246, 145, 211, 91, 189, 59, 56, 181,
                244, 75, 55, 105, 75, 172, 21, 66, 216, 191, 192, 228, 28, 103, 90, 9, 43, 89, 2,
                32, 79, 49, 84, 183, 41, 189, 18, 156, 43, 109, 137, 127, 116, 204, 95, 51, 17,
                110, 117, 195, 157, 131, 109, 105, 1, 144, 202, 212, 58, 167, 132, 158>>
            ]
          },
          %Aecore.Tx.SignedTx{
            data: %Aecore.Tx.DataTx{
              fee: 10,
              nonce: 1,
              payload: %Aecore.Account.Tx.SpendTx{
                amount: 10,
                payload: "",
                receiver: %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                },
                version: 1
              },
              senders: [
                %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                }
              ],
              ttl: 0,
              type: Aecore.Account.Tx.SpendTx
            },
            signatures: [
              <<48, 69, 2, 32, 73, 174, 169, 160, 11, 222, 171, 84, 119, 202, 5, 247, 199, 184,
                73, 192, 212, 96, 191, 179, 73, 70, 71, 24, 216, 236, 189, 15, 175, 3, 157, 146,
                2, 33, 0, 128, 105, 124, 219, 7, 173, 170, 46, 7, 172, 101, 254, 150, 26, 171,
                100, 111, 39, 228, 60, 249, 193, 135, 150, 72, 102, 237, 199, 76, 21, 214, 125>>
            ]
          },
          %Aecore.Tx.SignedTx{
            data: %Aecore.Tx.DataTx{
              fee: 11,
              nonce: 1,
              payload: %Aecore.Account.Tx.SpendTx{
                amount: 10,
                payload: "",
                receiver: %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                },
                version: 1
              },
              senders: [
                %Identifier{
                  type: :account,
                  value:
                    <<3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
                      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154>>
                }
              ],
              ttl: 0,
              type: Aecore.Account.Tx.SpendTx
            },
            signatures: [
              <<48, 69, 2, 32, 79, 191, 59, 15, 60, 27, 214, 3, 1, 89, 191, 153, 58, 82, 77, 213,
                122, 7, 53, 230, 196, 157, 187, 88, 135, 3, 122, 22, 104, 14, 91, 119, 2, 33, 0,
                148, 195, 72, 36, 5, 53, 241, 134, 161, 45, 65, 77, 200, 138, 136, 38, 92, 225,
                249, 76, 177, 10, 67, 18, 26, 113, 202, 108, 123, 138, 246, 184>>
            ]
          }
        ]
      },
      reason: nil,
      result: true,
      type: 14
    }
  end

  def mempool_response_binary do
    <<249, 1, 247, 1, 1, 14, 128, 185, 1, 240, 249, 1, 237, 1, 249, 1, 233, 184, 161, 248, 159,
      11, 1, 248, 73, 184, 71, 48, 69, 2, 33, 0, 238, 28, 94, 28, 181, 175, 246, 145, 211, 91,
      189, 59, 56, 181, 244, 75, 55, 105, 75, 172, 21, 66, 216, 191, 192, 228, 28, 103, 90, 9, 43,
      89, 2, 32, 79, 49, 84, 183, 41, 189, 18, 156, 43, 109, 137, 127, 116, 204, 95, 51, 17, 110,
      117, 195, 157, 131, 109, 105, 1, 144, 202, 212, 58, 167, 132, 158, 184, 80, 248, 78, 12, 1,
      227, 162, 1, 3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 162, 1, 3, 238,
      153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193, 150, 109, 175, 94, 92,
      187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 10, 12, 128, 1, 128, 184, 161, 248, 159,
      11, 1, 248, 73, 184, 71, 48, 69, 2, 32, 73, 174, 169, 160, 11, 222, 171, 84, 119, 202, 5,
      247, 199, 184, 73, 192, 212, 96, 191, 179, 73, 70, 71, 24, 216, 236, 189, 15, 175, 3, 157,
      146, 2, 33, 0, 128, 105, 124, 219, 7, 173, 170, 46, 7, 172, 101, 254, 150, 26, 171, 100,
      111, 39, 228, 60, 249, 193, 135, 150, 72, 102, 237, 199, 76, 21, 214, 125, 184, 80, 248, 78,
      12, 1, 227, 162, 1, 3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237,
      193, 150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 162, 1, 3,
      238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193, 150, 109, 175, 94,
      92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 10, 10, 128, 1, 128, 184, 161, 248,
      159, 11, 1, 248, 73, 184, 71, 48, 69, 2, 32, 79, 191, 59, 15, 60, 27, 214, 3, 1, 89, 191,
      153, 58, 82, 77, 213, 122, 7, 53, 230, 196, 157, 187, 88, 135, 3, 122, 22, 104, 14, 91, 119,
      2, 33, 0, 148, 195, 72, 36, 5, 53, 241, 134, 161, 45, 65, 77, 200, 138, 136, 38, 92, 225,
      249, 76, 177, 10, 67, 18, 26, 113, 202, 108, 123, 138, 246, 184, 184, 80, 248, 78, 12, 1,
      227, 162, 1, 3, 238, 153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193,
      150, 109, 175, 94, 92, 187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 162, 1, 3, 238,
      153, 246, 48, 67, 139, 193, 171, 24, 113, 29, 106, 32, 18, 237, 193, 150, 109, 175, 94, 92,
      187, 125, 212, 64, 214, 213, 55, 25, 74, 133, 154, 10, 11, 128, 1, 128>>
  end
end
