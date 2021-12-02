defmodule PBFT do
  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]
  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]
    use Cloak.Vault, otp_app: :my_app
  require Fuzzers
  require Logger
  defstruct(
    view: nil,
    current_primary: nil,
    heartbeat_timeout: nil,
    heartbeat_timer: nil,
    log: [],
    commit_index: 0,
    is_traitor: nil,
    is_primary: nil,
    next_index: nil,
    match_index: nil,
    database: nil,
    sequence_set: nil,
    sequence_upper_bound: nil,
    sequence_lower_bound: nil,
    account_book: nil,
    public_keys_list: nil,
    my_private_key: nil,
    my_public_key: nil,
    pre_prepare_log: [],
    prepare_log: [],
    commit_log: []
  )
  @spec new_configuration(
    [atom()],
    atom(),
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer(),
    [any()],
    any(),
    any()

  ) :: %PBFT{}
  def new_configuration(
    view,
    primary,
    heartbeat_timeout,
    sequence_upper_bound,
    sequence_lower_bound,
    public_keys_list,
    my_private_key,
    my_public_key
  ) do
  %PBFT{
    view: view,
    current_primary: primary,
    heartbeat_timeout: heartbeat_timeout,
    log: [],
    is_primary: false,
    database: %{}, # WDT: creation of a empty map, database[username] = amount of money, replace the queue in raft.
    sequence_set: MapSet.new(),
    sequence_upper_bound: sequence_upper_bound,
    sequence_lower_bound: sequence_lower_bound,
    account_book: MapSet.new(),
    public_keys_list: Map.new(),
    my_private_key: my_private_key,
    my_public_key: my_public_key
  }
  end

  @spec test_function()::no_return()
  def test_function() do
    IO.puts("test inside the PBFT.ex")
  end

  @doc """
  below is a function generating unique sequence,
  """
  @spec generate_unique_sequence(%PBFT{is_primary: true}, any(), any()) :: integer()
  def generate_unique_sequence(state, prepare_state, commit_state) do
    0
  end

  @doc """
  below is a function that sends message to all servers other than myself
  """
  @spec broadcast_to_others(%PBFT{}, any(),any(), any()) :: [boolean()]
  defp broadcast_to_others(state, message, prepare_state, commit_state) do
    me = whoami()
    state.view
    |> Enum.filter(fn pid -> pid != me end)
    |> Enum.map(fn pid -> send(pid, message) end)
  end


  @doc """
  below is a function that validates the signature.
  """
  @spec validation(%PBFT{is_primary: true}, any(), any() ,any()) :: boolean()
  def validation(state,signature, prepare_state, commit_state) do
    # # pretend receive the message...
    # rsa_pub_key = state.my_public_key
    # # break up the payload
    # parts = String.split(payload, "|")
    # recv_ts = Enum.fetch!(parts, 0)
    # recv_msg_serialized = Enum.fetch!(parts, 1)
    # {:ok, recv_sig} = Enum.fetch!(parts, 2) |> Base.url_decode64
    # # pretend ensure the time-stamp is not too old (or from the future)...
    # # it should probably no more than 5 minutes old, and no more than 15 minutes in the future
    # # verify the signature
    # {:ok, sig_valid} = ExPublicKey.verify("#{recv_ts}|#{recv_msg_serialized}", recv_sig, rsa_pub_key)
    # assert(sig_valid)
    # # un-serialize the JSON
    # recv_msg_unserialized = Poison.Parser.parse!(recv_msg_serialized)
    # # assert(msg == recv_msg_unserialized)
    true
  end

  @doc """
  below is a function that create and sign a signature using the private key.
  """
  @spec authentication(%PBFT{}, any(), any()) :: any()
  def authentication(state, prepare_state, commit_state) do
    # # load the RSA keys from a file on disk
    # rsa_priv_key = private_key
    # # create the message JSON
    # msg = %{"name_first"=>"Chuck","name_last"=>"Norris"}
    # # serialize the JSON
    # msg_serialized = Poison.encode!(msg)
    # # generate time-stamp
    # ts = DateTime.utc_now |> DateTime.to_unix
    # # add a time-stamp
    # ts_msg_serialized = "#{ts}|#{msg_serialized}"
    # # generate a secure hash using SHA256 and sign the message with the private key
    # {:ok, signature} = ExPublicKey.sign(ts_msg_serialized, rsa_priv_key)
    # # combine payload
    # # payload = "#{ts}|#{msg_serialized}|#{Base.url_encode64 signature}"
    # # payload
    # # pretend transmit the message...
    :signature
  end

  @doc """
  below is a function that make primary transit to sequence
  """
  @spec make_primary(%PBFT{}) :: no_return()
  def make_primary(state) do
    primary(%{state | is_primary: true}, %{}, %{})
  end

  @doc """
  below is a function that checks if the replica had received a pre-prepare message for view and sequence number for sequence_number containing a different digest
  """
  @spec check_v_n(%PBFT{},[atom()],non_neg_integer(),any()) :: boolean()
  def check_v_n(state,view,unique_sequence,extra_state) do
    true
  end


  @doc """
  below is a function that checks if the digest is the digest for message
  """
  @spec check_d(%PBFT{},any(),any(),any()) :: boolean()
  def check_d(state,digest,message,extra_state) do
    true
  end

  @doc """
  below is a function that checks if the sequence_number in the pre-prepare message is between a low water mark sequence_lower_bound and a higher water mark sequence_upper_bound
  """
  @spec check_n(%PBFT{}, non_neg_integer(), any(), any()) :: boolean()
  def check_n(state,uniqueSequenceNumber, prepare_state, commit_state) do
    true
  end

  @doc """
  below is a function that adds a messages to different logs
  """
  @spec add_to_log(%PBFT{},atom(),any(),any(), any()) :: no_return()
  def add_to_log(state,log_type,entry, prepare_state, commit_state) do
      case log_type do
      :pre_prepare->
        %{state | pre_prepare_log: [entry|state.pre_prepare_log]}
      :prepare->
        %{state | prepare_log: [entry|state.prepare_log]}
      :commit->
        %{state | commit_log: [entry|state.commit_log]}
      end
  end

  @doc """
  below is a function that digests a message, returing the digested message
  """
  @spec message_digest(%PBFT{},any(),any(), any())::any()
  def message_digest(state, message, prepare_state, commit_state) do
    :digest
  end
  @spec primary(%PBFT{is_primary: true}, any(), any()) :: no_return()
  def primary(state, prepare_state, commit_state) do
    receive do
      {sender, %PBFT.RequestMessage{
        timestamp: timestamp,
        message: message,
        signature: signature
      }} ->
        IO.puts("request recieved.")
        validation_result=validation(state, signature, prepare_state, commit_state)
        if validation_result==true do
          sequence_number=generate_unique_sequence(state, prepare_state, commit_state)
          sequence_number=timestamp
          primary_time_stamp=timestamp
          primary_view=length(state.view)
          primary_signature=authentication(state, prepare_state, commit_state)
          digest=message_digest(state, message, prepare_state, commit_state)
          pre_prepare_message=PBFT.PrePrepareMessage.new(primary_view,sequence_number,digest,primary_signature,message)

          broadcast_to_others(state,pre_prepare_message,prepare_state, commit_state)
        end
      send(sender, :ok)
      primary(state, prepare_state, commit_state)
      {sender, %PBFT.PrepareMessage{
        view: view_number,
        sequence_number: sequence_number,
        digest: digest,
        identity: id,
        signature: signature,
        }
      } -> 
        IO.puts("#{whoami()} received Prepare message: [#{view_number}, #{sequence_number}, #{digest}, #{id}, #{signature}].")
        if prepare_state[sequence_number] == nil do
          prepare_state = Map.put(prepare_state, sequence_number, [id])
          IO.puts("#{whoami()} has received #{length(prepare_state[sequence_number])} prepare messages for #{sequence_number}.")
          primary(state, prepare_state, commit_state)
        else
          prepare_state = Map.put(prepare_state, sequence_number, Enum.uniq([id] ++ prepare_state[sequence_number]))
          IO.puts("#{whoami()} has received #{length(prepare_state[sequence_number])} prepare messages for #{sequence_number}.")
          primary(state, prepare_state, commit_state)
        end
        primary(state, prepare_state, commit_state)
    end
  end

  @spec make_replica(%PBFT{}) :: no_return()
  def make_replica(state) do
    replica(%{state | is_primary: false}, %{}, %{})
  end

  @spec replica(%PBFT{is_primary: false}, any(), any()) :: no_return()
  def replica(state, prepare_state, commit_state) do
    #TODO: add timer and view_changing logic
    receive do
      {sender, %PBFT.PrePrepareMessage{
        view: view_number,
        sequence_number: sequence_number,
        digest: digest,
        signature: signature,
        message: message
        }
      } ->
        IO.puts("#{whoami()} received PrePrepare message: [#{view_number}, #{sequence_number}, #{digest}, #{signature}].")
        prepare_message=PBFT.PrepareMessage.new(view_number, sequence_number, digest, whoami(), signature)
        broadcast_to_others(state,prepare_message, prepare_state, commit_state)
        replica(state, prepare_state, commit_state)
        #prepare_message=PBFT.PrepareMessage.new(primary_view,sequence_number,digest,primary_signature,message)

      {sender, %PBFT.PrepareMessage{
        view: view_number,
        sequence_number: sequence_number,
        digest: digest,
        identity: id,
        signature: signature,
        }
      } -> 
        IO.puts("#{whoami()} received Prepare message: [#{view_number}, #{sequence_number}, #{digest}, #{id}, #{signature}].")
        if prepare_state[sequence_number] == nil do
          prepare_state = Map.put(prepare_state, sequence_number, [id])
          IO.puts("#{whoami()} has received #{length(prepare_state[sequence_number])} prepare messages for #{sequence_number}.")
          replica(state, prepare_state, commit_state)
        else
          prepare_state = Map.put(prepare_state, sequence_number, Enum.uniq([id] ++ prepare_state[sequence_number]))
          IO.puts("#{whoami()} has received #{length(prepare_state[sequence_number])} prepare messages for #{sequence_number}.")
          replica(state, prepare_state, commit_state)
        end
        replica(state, prepare_state, commit_state)

        #check signature
        #check previous log
        #check PBFT logic
        #multicast commit messag

      #{sender, %PBFT.CommitMessage{}} -> #TODO
        #replica(state, extra_state)
        #check signature
        #check previous log
        #check PBFT logic
        #commit
        #send reply
      {sender, %PBFT.RequestMessage{}} ->
        send(sender, {:redirect, state.current_primary})
        replica(state, prepare_state, commit_state)
    end

  end

end

defmodule PBFT.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  alias __MODULE__
  @enforce_keys [:primary, :timestamp]
  defstruct(primary: nil, timestamp: 0)

  @spec new_client(atom()) :: %Client{primary: atom(), timestamp: integer()}
  def new_client(member) do
    %Client{primary: member, timestamp: 0}
  end

  @spec new_account(%Client{}, any(), integer(), atom()) :: {%Client{}}
  def new_account(client, name, amount, client_pid) do
    primary = client.primary
    IO.puts("client timestamp is #{client.timestamp}.")
    client = %{client | timestamp: client.timestamp + 1}
    IO.puts("client timestamp is #{client.timestamp}.")
    send(primary, %PBFT.RequestMessage{timestamp: client.timestamp,
                                      message: PBFT.Message.new_account(name, amount, client_pid, client.timestamp),
                                      signature: nil})
    IO.puts("Message have been sent to #{client.primary}.")
    receive do
      {_, :ok} ->
        client
    end
  end

  @spec update_balance(%Client{}, any(), integer(), atom()) :: {%Client{}}
  def update_balance(client, name, amount, client_pid) do
    primary = client.primary
    IO.puts("client timestamp is #{client.timestamp}.")
    client = %{client | timestamp: client.timestamp + 1}
    IO.puts("client timestamp is #{client.timestamp}.")
    send(primary, %PBFT.RequestMessage{timestamp: client.timestamp,
                                      message: PBFT.Message.update_balance(name, amount, client_pid, client.timestamp),
                                      signature: nil})
    IO.puts("Message have been sent to #{client.primary}.")
    receive do
      {_, :ok} ->
        client
    end
  end
end
