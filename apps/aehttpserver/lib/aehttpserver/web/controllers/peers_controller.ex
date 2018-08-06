defmodule Aehttpserver.Web.PeersController do
  use Aehttpserver.Web, :controller

  alias Aecore.Peers.Worker, as: Peers
  alias Aecore.Keys.Peer, as: PeerKeys
  alias Aecore.Account.Account

  def info(conn, _params) do
    sync_port = Application.get_env(:aecore, :peers)[:sync_port]
    peer_pubkey = PeerKeys.keypair() |> elem(0) |> PeerKeys.base58c_encode()
    json(conn, %{port: sync_port, pubkey: peer_pubkey})
  end

  def peers(conn, _params) do
    peers = Peers.all_peers()

    serialized_peers =
      Enum.map(peers, fn peer -> %{peer | pubkey: Account.base58c_encode(peer.pubkey)} end)

    json(conn, serialized_peers)
  end
end
