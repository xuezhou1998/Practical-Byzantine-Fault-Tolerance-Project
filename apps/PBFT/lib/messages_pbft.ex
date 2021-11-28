defmodule PBFT.LogEntry do

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

    @spec update_balance(
      atom(),
      non_neg_integer(),
      atom(),
      any(),
      any(),
      non_neg_integer(),
      non_neg_integer(),
      any()
          ) ::
      %LogEntry{
              Client: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: non_neg_integer(),
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
            def update_balance(
              client,
      timeStamp,
      operation,
            message,
              digestOfMessage,
              view,
              uniqueSequenceNumber,
              signature
                ) do
              %LogEntry{
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

  defmodule PBFT.InitializeDigitalSignatureMessage do
    alias __MODULE__

    @enforce_keys [
      :my_public_key
    ]
    defstruct(
      my_public_key: nil
    )


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
      any(),
      non_neg_integer(),
      non_neg_integer(),
      any()
          ) ::
            %RequestMessage{
              Client: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: non_neg_integer(),
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
    def new(
      digestOfMessage,
      view,
      uniqueSequenceNumber,
      signature
        ) do
      %NewAccountMessage{
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
      any(),
      non_neg_integer(),
      non_neg_integer(),
      any()
          ) ::
            %PrePrepareMessage{
              Client: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: non_neg_integer(),
      UniqueSequenceNumber: non_neg_integer(),
      Signature: any()
            }
    def new(
      digestOfMessage,
      view,
      uniqueSequenceNumber,
      signature
        ) do
      %UpdataBalanceMessage{
        DigestOfMessage: digestOfMessage,
      View: view,
      UniqueSequenceNumber: uniqueSequenceNumber,
      Signature: signature
      }
    end
  end


  defmodule PBFT.PrePrepareMessage do
    alias __MODULE__

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
      any(),
      non_neg_integer(),
      non_neg_integer(),
      any()
          ) ::
            %PrepareMessage{
              Client: atom(),
      TimeStamp: non_neg_integer(),
      Operation: atom(),
      Message: any(),
              DigestOfMessage: any(),
      View: non_neg_integer(),
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
        atom(),
        non_neg_integer(),
        atom(),
        any(),any(),
        non_neg_integer(),
        non_neg_integer(),
        any()
            ) ::
              %CommitMessage{
                Client: atom(),
        TimeStamp: non_neg_integer(),
        Operation: atom(),
        Message: any(),
                DigestOfMessage: any(),
        View: non_neg_integer(),
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

defmodule PBFT.RequestMessage do

  alias __MODULE__

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
end
