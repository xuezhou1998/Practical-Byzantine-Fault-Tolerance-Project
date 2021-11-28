defmodule PBFT.LogEntry do

    @moduledoc """
    Log entry for PBFT implementation.
    """
    alias __MODULE__
    @enforce_keys [:index, :term]
    defstruct(
      index: nil,
      term: nil,
      operation: nil,
      requester: nil,
      argument: nil
    )

    @doc """
    Return an empty log entry, this is mostly
    used for convenience.
    """
    @spec empty() :: %LogEntry{index: 0, term: 0}
    def empty do
      %LogEntry{index: 0, term: 0}
    end

    @doc """
    Return a update_balance entry for the given index.
    """
    @spec update_balance(non_neg_integer(), non_neg_integer(), atom()) :: %LogEntry{
            index: non_neg_integer(),
            term: non_neg_integer(),
            requester: atom() | pid(),
            operation: :update_balance,
            argument: none()
          }
    def update_balance(index, term, requester) do
      %LogEntry{
        index: index,
        term: term,
        requester: requester,
        operation: :update_balance,
        argument: nil
      }
    end

    @doc """
    Return a log entry for an `new_account` operation.
    """
    @spec new_account(non_neg_integer(), non_neg_integer(), atom(), any()) ::
            %LogEntry{
              index: non_neg_integer(),
              term: non_neg_integer(),
              requester: atom() | pid(),
              operation: :enq,
              argument: any()
            }
    def new_account(index, term, requester, item) do
      %LogEntry{
        index: index,
        term: term,
        requester: requester,
        operation: :enq,
        argument: item
      }
    end
  end

  defmodule PBFT.InitializeDigitalSignatureMessage do
    @moduledoc """
    AppendEntries RPC request.
    """
    alias __MODULE__

    # Require that any AppendEntryRequest contains
    # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
    @enforce_keys [

    ]
    defstruct(

    )

    @doc """
    Create a new AppendEntryRequest
    """

    @spec new(
      any()
          ) ::
            %InitializeDigitalSignatureMessage{
              my_public_key: any()
            }
    def new(
      my_public_key
        ) do
      %InitializeDigitalSignatureMessage{
        my_public_key: my_public_key
      }
    end
  end

  defmodule PBFT.NewAccountMessage do
    @moduledoc """
    AppendEntries RPC request.
    """
    alias __MODULE__

    # Require that any AppendEntryRequest contains
    # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
    @enforce_keys [
      :Client,
      :TimeStamp,
      :Operation,
      :Message,
      :DigestOfMessage,
      :View,
      :UniqueSequenceNumber,
      :Signature
    ]
    defstruct(
      Client: nil,
      TimeStamp: nil,
      Operation: nil,
      Message: nil,
      DigestOfMessage: nil,
      View: nil,
      UniqueSequenceNumber: nil,
      Signature: nil
    )

    @doc """
    Create a new AppendEntryRequest
    """

    @spec new(
      atom(),
      non_neg_integer(),
      atom(),
      any(),
      [atom()],
      non_neg_integer(),
      any()
          ) ::
            %NewAccountMessage{
              lient: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: [atom()],
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
            def new(
              client,
      timeStamp,
      operation,
            message,
              digestOfMessage,
              view,
              uniqueSequenceNumber,
              signature
                ) do
              %NewAccountMessage{
                Client: client,
      TimeStamp: timeStamp,
      Operation: operation,
      Message: message,
                DigestOfMessage: digestOfMessage,
              View: view,
              UniqueSequenceNumber: uniqueSequenceNumber,
              Signature: signature
              }
            end
  end

  defmodule PBFT.UpdataBalanceMessage do
    @moduledoc """
    AppendEntries RPC request.
    """
    alias __MODULE__

    # Require that any AppendEntryRequest contains
    # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
    @enforce_keys [
      :Client,
      :TimeStamp,
      :Operation,
      :Message,
      :DigestOfMessage,
      :View,
      :UniqueSequenceNumber,
      :Signature
    ]
    defstruct(
      Client: nil,
      TimeStamp: nil,
      Operation: nil,
      Message: nil,
      DigestOfMessage: nil,
      View: nil,
      UniqueSequenceNumber: nil,
      Signature: nil
    )

    @doc """
    Create a new AppendEntryRequest
    """

    @spec new(
      atom(),
      non_neg_integer(),
      atom(),
      any(),
      [atom()],
      non_neg_integer(),
      any()
          ) ::
            %UpdataBalanceMessage{
              lient: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: [atom()],
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
            def new(
              client,
      timeStamp,
      operation,
            message,
              digestOfMessage,
              view,
              uniqueSequenceNumber,
              signature
                ) do
              %UpdataBalanceMessage{
                Client: client,
      TimeStamp: timeStamp,
      Operation: operation,
      Message: message,
                DigestOfMessage: digestOfMessage,
              View: view,
              UniqueSequenceNumber: uniqueSequenceNumber,
              Signature: signature
              }
            end
  end


  defmodule PBFT.PrePrepareMessage do
    @moduledoc """
    AppendEntries RPC request.
    """
    alias __MODULE__

    # Require that any AppendEntryRequest contains
    # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
    @enforce_keys [
      :DigestOfMessage,
      :View,
      :UniqueSequenceNumber,
      :Signature
    ]
    defstruct(
      DigestOfMessage: nil,
      View: nil,
      UniqueSequenceNumber: nil,
      Signature: nil
    )

    @doc """
    Create a new AppendEntryRequest
    """

    @spec new(
      any(),
      [atom()],
      non_neg_integer(),
      any()
          ) ::
            %PrePrepareMessage{
              DigestOfMessage: any(),
      View: [atom()],
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
            def new(
              digestOfMessage,
              view,
              uniqueSequenceNumber,
              signature
                ) do
              %PrePrepareMessage{
                DigestOfMessage: digestOfMessage,
              View: view,
              UniqueSequenceNumber: uniqueSequenceNumber,
              Signature: signature
              }
            end
  end

    defmodule PBFT.PrepareMessage do
      @moduledoc """
      AppendEntries RPC request.
      """
      alias __MODULE__

      # Require that any AppendEntryRequest contains
      # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
      @enforce_keys [
        :DigestOfMessage,
        :View,
        :UniqueSequenceNumber,
        :Signature
      ]
      defstruct(
        DigestOfMessage: nil,
        View: nil,
        UniqueSequenceNumber: nil,
        Signature: nil
      )

      @doc """
      Create a new AppendEntryRequest
      """

      @spec new(
        any(),
        [atom()],
        non_neg_integer(),
        any()
            ) ::
              %PrepareMessage{
                DigestOfMessage: any(),
        View: [atom()],
        UniqueSequenceNumber: non_neg_integer(),
        Signature: any()
              }
              def new(
                digestOfMessage,
                view,
                uniqueSequenceNumber,
                signature
                  ) do
                %PrepareMessage{
                  DigestOfMessage: digestOfMessage,
                View: view,
                UniqueSequenceNumber: uniqueSequenceNumber,
                Signature: signature
                }
              end
end
defmodule PBFT.CommitMessage do
  @moduledoc """
  AppendEntries RPC request.
  """
  alias __MODULE__

  # Require that any AppendEntryRequest contains
  # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
  @enforce_keys [
    :DigestOfMessage,
    :View,
    :UniqueSequenceNumber,
    :Signature
  ]
  defstruct(
    DigestOfMessage: nil,
    View: nil,
    UniqueSequenceNumber: nil,
    Signature: nil
  )

  @doc """
  Create a new AppendEntryRequest
  """

  @spec new(
    any(),
    [atom()],
    non_neg_integer(),
    any()
        ) ::
          %CommitMessage{
            DigestOfMessage: any(),
    View: [atom()],
    UniqueSequenceNumber: non_neg_integer(),
    Signature: any()
          }
          def new(
            digestOfMessage,
            view,
            uniqueSequenceNumber,
            signature
              ) do
            %CommitMessage{
              DigestOfMessage: digestOfMessage,
            View: view,
            UniqueSequenceNumber: uniqueSequenceNumber,
            Signature: signature
            }
          end
end

defmodule PBFT.ReplyMessage do
  @moduledoc """
  AppendEntries RPC request.
  """
  alias __MODULE__

  # Require that any AppendEntryRequest contains
  # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
  @enforce_keys [
    :DigestOfMessage,
    :View,
    :UniqueSequenceNumber,
    :Signature
  ]
  defstruct(
    DigestOfMessage: nil,
    View: nil,
    UniqueSequenceNumber: nil,
    Signature: nil
  )

  @doc """
  Create a new AppendEntryRequest
  """

  @spec new(
    any(),
    [atom()],
    non_neg_integer(),
    any()
        ) ::
          %ReplyMessage{
            DigestOfMessage: any(),
    View: [atom()],
    UniqueSequenceNumber: non_neg_integer(),
    Signature: any()
          }
          def new(
            digestOfMessage,
            view,
            uniqueSequenceNumber,
            signature
              ) do
            %ReplyMessage{
              DigestOfMessage: digestOfMessage,
            View: view,
            UniqueSequenceNumber: uniqueSequenceNumber,
            Signature: signature
            }
          end
end
