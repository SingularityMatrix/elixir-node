defmodule Aecore.Tx.DataTx do
  @moduledoc """
  Aecore structure of a transaction data.
  """
  alias Aecore.Naming.Tx.NamePreClaimTx
  alias Aecore.Naming.Tx.NameClaimTx
  alias Aecore.Naming.Tx.NameUpdateTx
  alias Aecore.Naming.Tx.NameTransferTx
  alias Aecore.Naming.Tx.NameRevokeTx
  alias Aecore.Tx.DataTx
  alias Aecore.Account.Tx.SpendTx
  alias Aeutil.Serialization
  alias Aeutil.Bits
  alias Aecore.Account.Account
  alias Aecore.Account.AccountStateTree
  alias Aecore.Oracle.Tx.OracleExtendTx
  alias Aecore.Oracle.Tx.OracleQueryTx
  alias Aecore.Oracle.Tx.OracleRegistrationTx
  alias Aecore.Oracle.Tx.OracleResponseTx
  alias Aecore.Keys.Wallet
  alias Aecore.Chain.Chainstate
  alias Aecore.Chain.Worker, as: Chain
  alias Aecore.Chain.Identifier

  require Logger

  @typedoc "Name of the specified transaction module"
  @type tx_types ::
          SpendTx
          | OracleExtendTx
          | OracleRegistrationTx
          | OracleQueryTx
          | OracleResponseTx
          | NamePreClaimTx
          | NameClaimTx
          | NameUpdateTx
          | NameTransferTx
          | NameRevokeTx

  @typedoc "Structure of a transaction that may be added to be blockchain"
  @type payload ::
          SpendTx.t()
          | OracleExtendTx.t()
          | OracleQueryTx.t()
          | OracleRegistrationTx.t()
          | OracleResponseTx.t()
          | NamePreClaimTx.t()
          | NameClaimTx.t()
          | NameUpdateTx.t()
          | NameTransferTx.t()
          | NameRevokeTx.t()

  @typedoc "Reason for the error"
  @type reason :: String.t()

  @typedoc "Structure of the main transaction wrapper"
  @type t :: %DataTx{
          type: tx_types(),
          payload: payload(),
          senders: list(binary()),
          fee: non_neg_integer(),
          nonce: non_neg_integer(),
          ttl: non_neg_integer()
        }

  @doc """
  Definition of Aecore DataTx structure

  ## Parameters
  - type: The type of transaction that may be added to the blockchain
  - payload: The strcuture of the specified transaction type
  - senders: The public addresses of the accounts originating the transaction. First element of this list is special - it's the main sender. Nonce is applied to main sender Account.
  - fee: The amount of tokens given to the miner
  - nonce: An integer bigger then current nonce of main sender Account. (see senders)
  """

  @account_bin_id Application.get_env(:aecore, :binary_ids)[:account]

  defstruct [:type, :payload, :senders, :fee, :nonce, :ttl]
  use ExConstructor

  def valid_types do
    [
      Aecore.Account.Tx.SpendTx,
      Aecore.Oracle.Tx.OracleExtendTx,
      Aecore.Oracle.Tx.OracleQueryTx,
      Aecore.Oracle.Tx.OracleRegistrationTx,
      Aecore.Oracle.Tx.OracleResponseTx,
      Aecore.Naming.Tx.NameClaimTx,
      Aecore.Naming.Tx.NamePreClaimTx,
      Aecore.Naming.Tx.NameRevokeTx,
      Aecore.Naming.Tx.NameTransferTx,
      Aecore.Naming.Tx.NameUpdateTx
    ]
  end

  @spec init(
          tx_types(),
          map(),
          list(binary()) | binary(),
          non_neg_integer(),
          integer(),
          non_neg_integer()
        ) :: t()
  def init(type, payload, senders, fee, nonce, ttl \\ 0) do
    if is_list(senders) do
      identified_senders =
        for sender <- senders do
          with {:ok, identified_senders} <- Identifier.create_identity(sender, :account) do
            identified_senders
          else
            {:error, msg} -> {:error, msg}
          end
        end

      %DataTx{
        type: type,
        payload: type.init(payload),
        senders: identified_senders,
        nonce: nonce,
        fee: fee,
        ttl: ttl
      }
    else
      {:ok, sender} = Identifier.create_identity(senders, :account)

      %DataTx{
        type: type,
        payload: type.init(payload),
        senders: [sender],
        nonce: nonce,
        fee: fee,
        ttl: ttl
      }
    end
  end

  @spec fee(t()) :: non_neg_integer()
  def fee(%DataTx{fee: fee}) do
    fee
  end

  @spec senders(t()) :: list(binary())
  def senders(%DataTx{senders: senders}) do
    for sender <- senders do
      sender.value
    end
  end

  @spec main_sender(t()) :: binary() | nil
  def main_sender(tx) do
    List.first(senders(tx))
  end

  @spec nonce(t()) :: non_neg_integer()
  def nonce(%DataTx{nonce: nonce}) do
    nonce
  end

  @spec ttl(t()) :: non_neg_integer()
  def ttl(%DataTx{ttl: ttl}) do
    case ttl do
      0 -> :max_ttl
      ttl -> ttl
    end
  end

  @spec payload(t()) :: map()
  def payload(%DataTx{payload: payload, type: type}) do
    if Enum.member?(valid_types(), type) do
      payload
    else
      Logger.error("Call to DataTx payload with invalid transaction type")
      %{}
    end
  end

  @doc """
  Checks whether the fee is above 0.
  """
  @spec validate(t(), non_neg_integer()) :: :ok | {:error, String.t()}
  def validate(%DataTx{fee: fee, type: type} = tx, block_height \\ Chain.top_height()) do
    cond do
      !Enum.member?(valid_types(), type) ->
        {:error, "#{__MODULE__}: Invalid tx type=#{type}"}

      fee < 0 ->
        {:error, "#{__MODULE__}: Negative fee"}

      !senders_pubkeys_size_valid?(tx.senders) ->
        {:error, "#{__MODULE__}: Invalid senders pubkey size"}

      DataTx.ttl(tx) < 0 ->
        {:error,
         "#{__MODULE__}: Invalid TTL value: #{DataTx.ttl(tx)} can't be a negative integer."}

      DataTx.ttl(tx) < block_height ->
        {:error,
         "#{__MODULE__}: Invalid or expired TTL value: #{DataTx.ttl(tx)}, with given block's height: #{
           block_height
         }"}

      true ->
        payload_validate(tx)
    end
  end

  @doc """
  Changes the chainstate (account state and tx_type_state) according
  to the given transaction requirements
  """
  @spec process_chainstate(Chainstate.t(), non_neg_integer(), t()) ::
          {:ok, Chainstate.t()} | {:error, String.t()}
  def process_chainstate(chainstate, block_height, %DataTx{fee: fee} = tx) do
    accounts_state = chainstate.accounts
    payload = payload(tx)

    tx_type_state = Map.get(chainstate, tx.type.get_chain_state_name(), %{})

    nonce_accounts_state =
      if Enum.empty?(tx.senders) do
        accounts_state
      else
        AccountStateTree.update(accounts_state, main_sender(tx), fn acc ->
          Account.apply_nonce!(acc, tx.nonce)
        end)
      end

    with {:ok, {new_accounts_state, new_tx_type_state}} <-
           nonce_accounts_state
           |> tx.type.deduct_fee(block_height, payload, tx, fee)
           |> tx.type.process_chainstate(
             tx_type_state,
             block_height,
             payload,
             tx
           ) do
      new_chainstate =
        if tx.type.get_chain_state_name() == :accounts do
          %{chainstate | accounts: new_accounts_state}
        else
          %{chainstate | accounts: new_accounts_state}
          |> Map.put(tx.type.get_chain_state_name(), new_tx_type_state)
        end

      {:ok, new_chainstate}
    else
      err ->
        err
    end
  end

  @spec preprocess_check(Chainstate.t(), non_neg_integer(), t()) :: :ok | {:error, String.t()}
  def preprocess_check(chainstate, block_height, tx) do
    accounts_state = chainstate.accounts
    payload = payload(tx)
    tx_type_state = Map.get(chainstate, tx.type.get_chain_state_name(), %{})

    with :ok <- tx.type.preprocess_check(accounts_state, tx_type_state, block_height, payload, tx) do
      if main_sender(tx) == nil || Account.nonce(chainstate.accounts, main_sender(tx)) < tx.nonce do
        :ok
      else
        {:error, "#{__MODULE__}: Too small nonce"}
      end
    else
      err ->
        err
    end
  end

  @spec serialize(map()) :: map()
  def serialize(%DataTx{} = tx) do
    # payload needs adjustments
    # serialized_receiver = Serialization.serialize_value(tx.payload.receiver)
    # Map.put(tx.payload, "receiver", tx.payload.receiver.value)

    map_without_senders = %{
      "type" => Serialization.serialize_value(tx.type),
      "payload" => Serialization.serialize_value(tx.payload),
      "fee" => Serialization.serialize_value(tx.fee),
      "nonce" => Serialization.serialize_value(tx.nonce),
      "ttl" => Serialization.serialize_value(tx.ttl)
    }

    if length(tx.senders) == 1 do
      Map.put(
        map_without_senders,
        "sender",
        Serialization.serialize_value(main_sender(tx), :sender)
      )
    else
      Map.put(map_without_senders, "senders", Serialization.serialize_value(tx.senders, :sender))
    end
  end

  @spec deserialize(map()) :: t()
  def deserialize(%{sender: sender} = data_tx) do
    init(data_tx.type, data_tx.payload, [sender], data_tx.fee, data_tx.nonce, data_tx.ttl)
  end

  def deserialize(%{senders: senders} = data_tx) do
    init(data_tx.type, data_tx.payload, senders, data_tx.fee, data_tx.nonce, data_tx.ttl)
  end

  def base58c_encode(bin) do
    Bits.encode58c("th", bin)
  end

  def base58c_decode(<<"th$", payload::binary>>) do
    Bits.decode58(payload)
  end

  def base58c_decode(_) do
    {:error, "#{__MODULE__}: Wrong data"}
  end

  @spec standard_deduct_fee(
          Chainstate.accounts(),
          non_neg_integer(),
          t(),
          non_neg_integer()
        ) :: Chainstate.accounts()
  def standard_deduct_fee(accounts, block_height, data_tx, fee) do
    sender = DataTx.main_sender(data_tx)

    AccountStateTree.update(accounts, sender, fn acc ->
      Account.apply_transfer!(acc, block_height, fee * -1)
    end)
  end

  defp payload_validate(%DataTx{type: type, payload: payload} = data_tx) do
    payload
    |> type.validate(data_tx)
  end

  defp senders_pubkeys_size_valid?([sender | rest]) do
    if Wallet.key_size_valid?(sender.value) do
      senders_pubkeys_size_valid?(rest)
    else
      false
    end
  end

  defp senders_pubkeys_size_valid?([]) do
    true
  end

  @spec rlp_encode(non_neg_integer(), non_neg_integer(), t()) :: binary() | {:error, String.t()}
  def rlp_encode(tag, version, term) do
    encode(tag, version, term)
  end

  defp encode(tag, version, %DataTx{type: SpendTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_receiver} = Identifier.encode_data(tx.payload.receiver)

    list = [
      tag,
      version,
      senders,
      encoded_receiver,
      tx.payload.amount,
      tx.fee,
      tx.ttl,
      tx.nonce,
      tx.payload.payload
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: OracleRegistrationTx} = tx) do
    ttl_type = Serialization.encode_ttl_type(tx.payload.ttl)

    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      # TODO workarounds, adjustments should be made as soon as fields types are adjusted
      "$æx" <> Serialization.transform_item(tx.payload.query_format),
      # TODO workarounds, adjustments should be made as soon as fields types are adjusted
      "$æx" <> Serialization.transform_item(tx.payload.response_format),
      tx.payload.query_fee,
      ttl_type,
      tx.payload.ttl.ttl,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: OracleQueryTx} = tx) do
    ttl_type_q = Serialization.encode_ttl_type(tx.payload.query_ttl)
    ttl_type_r = Serialization.encode_ttl_type(tx.payload.response_ttl)

    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_oracle_address} = Identifier.encode_data(tx.payload.oracle_address)

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      encoded_oracle_address,
      "$æx" <> Serialization.transform_item(tx.payload.query_data),
      tx.payload.query_fee,
      ttl_type_q,
      tx.payload.query_ttl.ttl,
      ttl_type_r,
      tx.payload.response_ttl.ttl,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: OracleResponseTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      tx.payload.query_id,
      # TODO workarounds, adjustments should be made as soon as fields types are adjusted
      "$æx" <> Serialization.transform_item(tx.payload.response),
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: OracleExtendTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      tx.payload.ttl,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: NamePreClaimTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_commitment} = Identifier.encode_data(tx.payload.commitment)

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      encoded_commitment,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: NameClaimTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      tx.payload.name,
      tx.payload.name_salt,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: NameUpdateTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_hash} = Identifier.encode_data(tx.payload.hash)

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      encoded_hash,
      tx.payload.client_ttl,
      tx.payload.pointers,
      tx.payload.expire_by,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: NameRevokeTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_hash} = Identifier.encode_data(tx.payload.hash)

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      encoded_hash,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  defp encode(tag, version, %DataTx{type: NameTransferTx} = tx) do
    senders =
      for acc <- tx.senders do
        case Identifier.encode_data(acc) do
          {:ok, tagged_pub_key} -> tagged_pub_key
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, encoded_target} = Identifier.encode_data(tx.payload.target)
    {:ok, encoded_name_hash} = Identifier.encode_data(tx.payload.hash)

    list = [
      tag,
      version,
      senders,
      tx.nonce,
      encoded_name_hash,
      encoded_target,
      tx.fee,
      tx.ttl
    ]

    try do
      ExRLP.encode(list)
    rescue
      e -> {:error, "#{__MODULE__}: " <> Exception.message(e)}
    end
  end

  def rlp_encode(data) do
    {:error, "#{__MODULE__} : Invalid DataTx serializations: #{inspect(data)}"}
  end

  @spec rlp_decode(non_neg_integer(), list()) :: tx_types() | {:error, String.t()}
  def rlp_decode(tag, values) when is_list(values) do
    decode(tag, values)
  end

  defp decode(SpendTx, [
         encoded_senders,
         encoded_receiver,
         amount,
         fee,
         ttl,
         nonce,
         payload
       ]) do
    {:ok, vsn} = Serialization.get_version(SpendTx)

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, receiver} = Identifier.decode_data(encoded_receiver)

    DataTx.init(
      SpendTx,
      %{
        receiver: receiver,
        amount: Serialization.transform_item(amount, :int),
        version: vsn,
        payload: payload
      },
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(OracleQueryTx, [
         encoded_senders,
         nonce,
         encoded_oracle_address,
         encoded_query_data,
         query_fee,
         encoded_query_ttl_type,
         query_ttl_value,
         encoded_response_ttl_type,
         response_ttl_value,
         fee,
         ttl
       ]) do
    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, oracle_address} = Identifier.decode_data(encoded_oracle_address)

    query_ttl_type =
      encoded_query_ttl_type
      |> Serialization.transform_item(:int)
      |> Serialization.decode_ttl_type()

    response_ttl_type =
      encoded_response_ttl_type
      |> Serialization.transform_item(:int)
      |> Serialization.decode_ttl_type()

    query_data = decode_format(encoded_query_data)

    payload = %{
      oracle_address: oracle_address,
      query_data: query_data,
      query_fee: Serialization.transform_item(query_fee, :int),
      query_ttl: %{ttl: Serialization.transform_item(query_ttl_value, :int), type: query_ttl_type},
      response_ttl: %{
        ttl: Serialization.transform_item(response_ttl_value, :int),
        type: response_ttl_type
      }
    }

    DataTx.init(
      OracleQueryTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(OracleRegistrationTx, [
         encoded_senders,
         nonce,
         encoded_query_format,
         encoded_response_format,
         query_fee,
         encoded_ttl_type,
         ttl_value,
         fee,
         ttl
       ]) do
    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    ttl_type =
      encoded_ttl_type
      |> Serialization.transform_item(:int)
      |> Serialization.decode_ttl_type()

    query_format = decode_format(encoded_query_format)

    response_format = decode_format(encoded_response_format)

    payload = %{
      query_format: query_format,
      response_format: response_format,
      ttl: %{ttl: Serialization.transform_item(ttl_value, :int), type: ttl_type},
      query_fee: Serialization.transform_item(query_fee, :int)
    }

    DataTx.init(
      OracleRegistrationTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(OracleResponseTx, [
         encoded_senders,
         nonce,
         encoded_query_id,
         encoded_response,
         fee,
         ttl
       ]) do
    query_id = decode_format(encoded_query_id)
    response = decode_format(encoded_response)

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    payload = %{
      query_id: query_id,
      response: response
    }

    DataTx.init(
      OracleResponseTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(OracleExtendTx, [encoded_senders, nonce, ttl_value, fee, ttl]) do
    payload = %{
      ttl: Serialization.transform_item(ttl_value, :int)
    }

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    DataTx.init(
      OracleExtendTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(NamePreClaimTx, [encoded_senders, nonce, encoded_commitment, fee, ttl]) do
    {:ok, decoded_commitment} = Identifier.decode_data(encoded_commitment)
    payload = %NamePreClaimTx{commitment: decoded_commitment}

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    DataTx.init(
      NamePreClaimTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(NameClaimTx, [encoded_senders, nonce, name, name_salt, fee, ttl]) do
    payload = %NameClaimTx{name: name, name_salt: name_salt}

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    DataTx.init(
      NameClaimTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(NameUpdateTx, [
         encoded_senders,
         nonce,
         hash,
         client_ttl,
         pointers,
         expire_by,
         fee,
         ttl
       ]) do
    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    {:ok, decoded_hash} = Identifier.decode_data(hash)

    payload = %NameUpdateTx{
      client_ttl: Serialization.transform_item(ttl, :int),
      expire_by: Serialization.transform_item(expire_by, :int),
      hash: decoded_hash,
      pointers: pointers
    }

    DataTx.init(
      NameUpdateTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(NameRevokeTx, [encoded_senders, nonce, encoded_hash, fee, ttl]) do
    {:ok, hash} = Identifier.decode_data(encoded_hash)
    payload = %NameRevokeTx{hash: hash}

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    DataTx.init(
      NameRevokeTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(NameTransferTx, [encoded_senders, nonce, hash, recipient, fee, ttl]) do
    {:ok, decoded_hash} = Identifier.decode_data(hash)
    {:ok, decoded_recipient} = Identifier.decode_data(recipient)
    payload = %NameTransferTx{hash: decoded_hash, target: decoded_recipient}

    senders =
      for sender <- encoded_senders do
        case Identifier.decode_data(sender) do
          {:ok, extracted_data} -> extracted_data
          {:error, msg} -> {:error, msg}
        end
      end

    DataTx.init(
      NameTransferTx,
      payload,
      senders,
      Serialization.transform_item(fee, :int),
      Serialization.transform_item(nonce, :int),
      Serialization.transform_item(ttl, :int)
    )
  end

  defp decode(tx_type, tx_data) do
    {:error,
     "#{__MODULE__}: Unknown DataTx structure: #{inspect(tx_type)}, TX's data: #{inspect(tx_data)} "}
  end

  # Optional function-workaround:
  # As we have differences in value types in some fields,
  # which means that we encode these fields different apart from what Epoch does,
  # we need to recognize the origins of this value.
  # My proposal is (until the problem is solved) to add
  # specific prefix to the data before encodings, for example, "$æx"
  # this prefix will allow us to know, how the data should be handled.
  # But it also makes problems and inconsistency in Epoch, because they dont handle these prefixes.
  @spec decode_format(binary()) :: binary()
  defp decode_format(<<"$æx", binary::binary>>) do
    Serialization.transform_item(binary, :binary)
  end

  defp decode_format(binary) when is_binary(binary) do
    binary
  end
end
