defmodule Aecore.Structures.SignedTx do
  @moduledoc """
  Aecore structure of a signed transaction.
  """

  alias Aecore.Structures.ContractCallTxData
  alias Aecore.Structures.SpendTx
  alias Aecore.Structures.SignedTx
  alias Aewallet.Signing
  alias Aeutil.Serialization
  alias Aeutil.Bits

  @typedoc "Structure of the SignedTx module"
  @type t :: %SignedTx{
          data: SpendTx.t(),
          signature: binary()
        }

  @doc """
  Definition of Aecore SignedTx structure

  ## Parameters
     - data: Aecore %SpendTx{} structure
     - signature: Signed %SpendTx{} with the private key of the sender
  """
  defstruct [:data, :signature]
  use ExConstructor

  @spec is_coinbase?(SignedTx.t()) :: boolean()
  def is_coinbase?(tx) do
    if match?(%SpendTx{}, tx.data) do
      tx.data.from_acc == nil && tx.signature == nil
    else
      false
    end
  end

  @spec is_valid?(SignedTx.t()) :: boolean()
  def is_valid?(tx) do
    case tx.data do
      %SpendTx{} ->
        tx.data.value >= 0 && tx.data.fee >= 0 &&
          Signing.verify(Serialization.pack_binary(tx.data), tx.signature, tx.data.from_acc)

      %ContractCallTxData{} ->
        if Map.has_key?(Chain.proposed_contracts(), tx.data.contract_proposal_tx_hash) do
          true
        else
          false
        end

      _ ->
        true
    end
  end

  @doc """
  Takes the transaction that needs to be signed
  and the private key of the sender.
  Returns a signed tx
  ## Parameters
     - tx: The transaction data that it's going to be signed
     - priv_key: The priv key to sign with
  """
  @spec sign_tx(SpendTx.t(), binary()) :: {:ok, SignedTx.t()}
  def sign_tx(%SpendTx{} = tx, priv_key) when byte_size(priv_key) == 32 do
    signature = Signing.sign(Serialization.pack_binary(tx), priv_key)
    {:ok, %SignedTx{data: tx, signature: signature}}
  end

  def sign_tx(tx, _priv_key) do
    {:error, "Wrong Transaction data structure"}
  end

  @spec hash_tx(SignedTx.t()) :: binary()
  def hash_tx(%SignedTx{data: data}) do
    :crypto.hash(:sha256, Serialization.pack_binary(data))
  end

  @spec bech32_encode(binary()) :: String.t()
  def bech32_encode(bin) do
    Bits.bech32_encode("tx", bin)
  end

  @spec bech32_encode_root(binary()) :: String.t()
  def bech32_encode_root(bin) do
    Bits.bech32_encode("tr", bin)
  end
end
