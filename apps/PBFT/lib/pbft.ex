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
    non_neg_integer(),
    non_neg_integer(),
    [any()],
    any(),
    any(),
    [any()],
    [any()],
    [any()]
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
  is_primary: false,
  database: %{}, # WDT: creation of a empty map, database[username] = amount of money, replace the queue in raft.
  sequence_set: MapSet.new(),
    sequence_upper_bound: sequence_upper_bound,
    sequence_lower_bound: sequence_lower_bound,
    account_book: MapSet.new(),
    public_keys_list: Map.new(),
    my_private_key: my_private_key,
    my_public_key: my_public_key,
    pre_prepare_log: [],
    prepare_log: [],
    commit_log: []
  }
  end

  # @spec initialize_digital_signatures(%PBFT{}) :: no_return()
  # def initialize_digital_signatures(state) do

  #   broadcast_to_others(state,state.my_public_key)
  # end

  @spec generate_unique_sequence(%PBFT{is_primary: true}, any()) :: integer()
  def generate_unique_sequence(state, extra_state) do
    0
  end

  @spec broadcast_to_others(%PBFT{}, any(),any()) :: [boolean()]
  defp broadcast_to_others(state, message, extra_state) do
    me = whoami()
    state.view
    |> Enum.filter(fn pid -> pid != me end)
    |> Enum.map(fn pid -> send(pid, message) end)
  end

  @spec validation(%PBFT{is_primary: true},any() ,any()) :: boolean()
  def validation(state,signature, extra_state) do
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
  @spec authentication(%PBFT{},any()) :: any()
  def authentication(state, extra_state) do
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
  # @spec pre_prepare(%PBFT{is_primary: true},any(),[atom()],non_neg_integer(),any())::boolean()
  # def pre_prepare(state,digest_of_message,view,sequence_number,signature) do
  #   msg=PBFT.PrePrepareMessage.new(digest_of_message,view,sequence_number,signature)
  #   hear_back=broadcast_to_others(state, msg)
  #   {_,encrpted_msg}=MyApp.Vault.encrypt("plaintext")
  #   hear_back
  # end


  @spec check_v_n(%PBFT{},[atom()],non_neg_integer(),any()) :: boolean()
  def check_v_n(state,external_view,unique_sequence_number,extra_state) do
    true
  end
  @spec check_d(%PBFT{},any(),any(),any()) :: boolean()
  def check_d(state,digestOfMessage,message,extra_state) do
    true
  end
  @spec check_n(%PBFT{},non_neg_integer(),any()) :: boolean()
  def check_n(state,uniqueSequenceNumber,extra_state) do
    true
  end
  @spec add_to_log(%PBFT{},atom(),any(),any()) :: no_return()
  def add_to_log(state,log_type,entry,extra_state) do
      case log_type do
      :pre_prepare->
        %{state | pre_prepare_log: [entry|state.pre_prepare_log]}
      :prepare->
        %{state | prepare_log: [entry|state.prepare_log]}
      :commit->
        %{state | commit_log: [entry|state.commit_log]}
      end
  end
  @spec primary(%PBFT{is_primary: true}, any()) :: no_return()
  def primary(state, extra_state) do
    receive do
      {sender, %PBFT.RequestMessage{
        Client: client,
        TimeStamp: _timeStamp,
        Operation: operation,
        Message: message,
        DigestOfMessage: digestOfMessage,
        View: _view,
        UniqueSequenceNumber: _UniqueSequenceNumber,
        Signature: client_signature
        }
      }->

        validation_result=validation(state,client_signature,extra_state)
        if validation_result==true do
          uniq_seq=generate_unique_sequence(state,extra_state)
          primary_time_stamp=now()
          primary_view=state.view
          primary_signature=authentication(state,extra_state)

          pre_prepare_message=PBFT.PrePrepareMessage.new(
          client,
          primary_time_stamp,
          operation,
          message,
          digestOfMessage,
          primary_view,
          uniq_seq,
          primary_signature)

          broadcast_to_others(state,pre_prepare_message)
        end
        # TODO: You might need to update the following call.
        primary(state, extra_state)
    end
  end

  @spec replica(%PBFT{is_primary: false}, any()) :: no_return()
  def replica(state, extra_state) do
    #TODO: add timer and view_changing logic
    receive do
      {sender, %PBFT.PrePrepareMessage{
        Client: client,
        TimeStamp: timeStamp,
        Operation: operation,
        Message: message,
        DigestOfMessage: digestOfMessage,
        View: view,
        UniqueSequenceNumber: uniqueSequenceNumber,
        Signature: signature
      }} -> #TODO
        #check signature
        validation_result=validation(state,signature)
        if validation_result==true do
          #check it is in v and d is correct for m
          #check other{v, n}doesn't exist
          check_v_n_result=check_v_n(state,view,uniqueSequenceNumber,extra_state)

          if check_v_n_result==true do
            check_d_result=check_d(state,digestOfMessage,message,extra_state)
            if check_d_result==true do
              check_n_result=check_n(state,uniqueSequenceNumber,extra_state)
              if check_n_result==true do
                #add to pre_prepare log
                state_1=add_to_log(state,:pre_prepare,new_entry,extra_state)
                #create prepare message
                prepare_msg=PBFT.
                #add to prepare log
                #multicast prepare message
              end
            end

          end

        end


      {sender, %PBFT.PrepareMessage{

      }} -> #TODO
        #check signature
        #check previous log
        #check PBFT logic
        #multicast commit messag


      {sender, %PBFT.CommitMessage{}} -> #TODO
        #check signature
        #check previous log
        #check PBFT logic
        #commit
        #send reply
        nil
      {sender, %PBFT.RequestMessage{}} ->
        send(sender, {:redirect, state.current_leader})
        replica(state, extra_state)


    end

  end

end

defmodule PBFT.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  alias __MODULE__
  @enforce_keys [:leader]
  defstruct(leader: nil)

  @spec new_client(atom()) :: %Client{leader: atom()}
  def new_client(member) do
    %Client{leader: member}
  end

  @spec newaccount(%Client{}, %PBFT.RequestMessage{}) :: {:ok, %Client{}}
  def newaccount(client, item) do
    leader = client.leader
    send(leader, item)

    receive do
      {_, :ok} ->
        {:ok, client}

      {_, {:redirect, new_leader}} ->
        newaccount(%{client | leader: new_leader}, item)
    end
  end

  @spec updatebalance(%Client{}, %PBFT.RequestMessage{}) :: {:ok, %Client{}}
  def updatebalance(client, item) do
    leader = client.leader
    send(leader, item)

    receive do
      {_, :ok} ->
        {:ok, client}

      {_, {:redirect, new_leader}} ->
        newaccount(%{client | leader: new_leader}, item)
    end
  end
end
