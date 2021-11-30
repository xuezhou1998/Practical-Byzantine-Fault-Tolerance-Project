# message = {operation, username, amount}
# message's content is meaningless unless being commited
# message instance: {:newaccount, "Tom", 1000, :client1, 1}, {:updatebalance, "Tom", 400, :client1, 2}
defmodule PBFT.Message do
  alias __MODULE__
  @enforce_keys [
    :op,
    :name,
    :amount,
    :client,
    :timestamp
  ]
  defstruct(
    op: nil,
    name: nil,
    amount: nil,
    client: nil,
    timestamp: 0
  )
  @spec new_account(atom(), integer(), atom(), integer()) :: %Message{
            op: :newaccount,
            name: atom(),
            amount: integer(),
            client: atom(),
            timestamp: non_neg_integer()
          }
  def new_account(n, a, c, t) do
    %Message{
      op: :newaccount,
      name: n,
      amount: a,
      client: c,
      timestamp: t
    }
  end

  @spec update_balance(any(), integer(), atom(), integer()) :: %Message{
    op: :updatebalance,
    name: any(),
    amount: integer(),
    client: atom(),
    timestamp: non_neg_integer()
  }
  def update_balance(n, a, c, t) do
    %Message{
      op: :updatebalance,
      name: n,
      amount: a,
      client: c,
      timestamp: t
    }
  end
end

defmodule PBFT.RequestMessage do
  alias __MODULE__
  @enforce_keys [
    :timestamp,
    :message,
    :signature
  ]
  defstruct(
    timestamp: nil,
    message: nil,
    signature: nil
  )
  @spec new(non_neg_integer(), any(), any()) ::
          %RequestMessage{
            timestamp: non_neg_integer(),
            message: any(),
            signature: any()
          }
  def new(timestamp,message,signature) do
    %RequestMessage{
      timestamp: timestamp,
      message: message,
      signature: signature
    }
  end
end

defmodule PBFT.PrePrepareMessage do
  alias __MODULE__
  @enforce_keys [
    :view,
    :sequence_number,
    :digest,
    :signature,
    :message
  ]
  defstruct(
    view: nil,
    sequence_number: 0,
    digest: nil,
    signature: nil,
    message: nil
  )
  @spec new(non_neg_integer(), non_neg_integer(), any(), any(), any()) ::
          %PrePrepareMessage{
            view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            digest: any(),
            signature: any(),
            message: any()
          }
  def new(view,sequence_number,digest,signature,message) do
    %PrePrepareMessage{
      view: view,
      sequence_number: sequence_number,
      digest: digest,
      signature: signature,
      message: message
    }
  end
end

defmodule PBFT.PrepareMessage do
  alias __MODULE__
  @enforce_keys [
    :view,
    :sequence_number,
    :digest,
    :identity, # "i"
    :signature
  ]
  defstruct(
    view: nil,
    sequence_number: 0,
    digest: nil,
    identity: nil,
    signature: nil
  )
  @spec new(non_neg_integer(),non_neg_integer(),any(),any(),any()) ::
          %PrepareMessage{
            view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            digest: any(),
            identity: any(),
            signature: any()
          }
  def new(view,sequence_number,digest,identity,signature) do
    %PrepareMessage{
      view: view,
      sequence_number: sequence_number,
      digest: digest,
      identity: identity,
      signature: signature

    }
  end
end

defmodule PBFT.CommitMessage do
  alias __MODULE__
  @enforce_keys [
    :view,
    :sequence_number,
    :digest,
    :identity,
    :signature
  ]
  defstruct(
    view: nil,
    sequence_number: 0,
    digest: nil,
    identity: nil,
    signature: nil
  )
  @spec new(non_neg_integer(),non_neg_integer(),any(),any(),any()) ::
          %CommitMessage{
            view: non_neg_integer(),
            sequence_number: non_neg_integer(),
            digest: any(),
            identity: any(),
            signature: any()
          }
  def new(view,sequence_number,digest,identity,signature) do
    %CommitMessage{
      view: view,
      sequence_number: sequence_number,
      digest: digest,
      identity: identity,
      signature: signature
    }
  end
end

defmodule PBFT.ReplyMessage do
  alias __MODULE__

  @enforce_keys [
    :view,
    :message,
    :identity,
    :result,
    :signature,
  ]
  defstruct(
    view: 0,
    message: nil,
    identity: nil,
    result: false,
    signature: nil
  )
  @spec new(non_neg_integer(),any(),any(),any(),any()) ::
          %ReplyMessage{
            view: non_neg_integer(),
    message: any(),
    identity: any(),
    result: any(),
    signature: any()
          }
  def new(view, message, identity, result, signature) do
    %ReplyMessage{
      view: view,
    message: message,
    identity: identity,
    result: result,
    signature: signature
    }
  end
end
