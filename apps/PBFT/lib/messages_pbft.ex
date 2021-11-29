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
  @spec new_account(any(), integer(), atom(), integer()) :: %Message{
            op: :newaccount,
            name: any(),
            amount: integer(),
            client: atom(),
            timestamp: integer()
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
    timestamp: integer()
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
end