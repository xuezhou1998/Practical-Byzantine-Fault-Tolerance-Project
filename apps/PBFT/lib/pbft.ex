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

    pre_prepare_log: nil,
    prepare_log: nil,

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
    my_public_key: nil
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
  commit_index: 0,
  last_applied: 0,
  is_primary: false,
  next_index: nil,
  match_index: nil,
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

  @spec initialize_digital_signatures(%PBFT{}) :: no_return()
  def initialize_digital_signatures(state) do

    broadcast_to_others(state,state.my_public_key)
  end

  @spec generate_unique_sequence(%PBFT{is_primary: true}, any()) :: integer()
  def generate_unique_sequence(state, extra_state) do
    0
  end

  @spec broadcast_to_others(%PBFT{}, any()) :: [boolean()]
  defp broadcast_to_others(state, message) do
    me = whoami()

    state.view
    |> Enum.filter(fn pid -> pid != me end)
    |> Enum.map(fn pid -> send(pid, message) end)
  end

  @spec validation(%PBFT{is_primary: true},any(),[atom()],non_neg_integer(),any() ) :: boolean()
  def validation(state,digest_of_message,view,sequence_number,signature) do
    true
  end

  @spec pre_prepare(%PBFT{is_primary: true},any(),[atom()],non_neg_integer(),any())::boolean()
  def pre_prepare(state,digest_of_message,view,sequence_number,signature) do
    msg=PBFT.PrePrepareMessage.new(digest_of_message,view,sequence_number,signature)
    hear_back=broadcast_to_others(state, msg)
    {_,encrpted_msg}=MyApp.Vault.encrypt("plaintext")
    hear_back
  end

  @spec primary(%PBFT{is_primary: true}, any()) :: no_return()
  def primary(state, extra_state) do
    receive do
      {sender, %PBFT.UpdataBalanceMessage{
        Client: client,
        TimeStamp: timeStamp,
        Operation: operation,
        Message: message,
        DigestOfMessage: digestOfMessage,
        View: view,
        UniqueSequenceNumber: uniqueSequenceNumber,
        Signature: signature
        }
      }->
        validation_result=validation(state,digestOfMessage,view,uniqueSequenceNumber,signature)
        if validation_result==true do
          uniq_seq=generate_unique_sequence(state,extra_state)
          pre_prepare_message=PBFT.PrePrepareMessage.new()
          broadcast_to_others(state,pre_prepare_message)
        end
        {sender, %PBFT.NewAccountMessage{
          Client: client,
          TimeStamp: timeStamp,
          Operation: operation,
          Message: message,
          DigestOfMessage: digestOfMessage,
          View: view,
          UniqueSequenceNumber: uniqueSequenceNumber,
          Signature: signature
          }
        }->
          validation_result=validation(state,digestOfMessage,view,uniqueSequenceNumber,signature)
          if validation_result==true do
            uniq_seq=generate_unique_sequence(state,extra_state)
            pre_prepare_message=PBFT.PrePrepareMessage.new()
            broadcast_to_others(state,pre_prepare_message)
          end


        # TODO: You might need to update the following call.
        primary(s1, extra_state)
    end
  end

  @spec replica(%PBFT{is_primary: false}, any()) :: no_return()
  def replica(state, extra_state) do
    #TODO: add timer and view_changing logic
    receive do
      {sender, %PBFT.PrePrepareMessage{}} -> #TODO
        #check signature
        #check it is in v and d is correct for m
        #check other{v, n}doesn't exist
        #add to pre_prepare log
        #create prepare message
        #add to prepare log
        #multicast prepare message
      {sender, %PBFT.PrepareMessage{}} -> #TODO
        #check signature
        #check previous log
        #check PBFT logic
        #multicast commit message
      {sender, %PBFT.CommitMessage{}} -> #TODO
        #check signature
        #check previous log
        #check PBFT logic
        #commit
        #send reply
      {sender, %PBFT.UpdataBalanceMessage{}} ->
        send(sender, {:redirect, state.current_leader})
        replica(state, extra_state)

      {sender, %PBFT.NewAccountMessage{}} ->
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

  @spec newaccount(%Client{}, %PBFT.NewAccountMessage{}) :: {:ok, %Client{}}
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

  @spec updatebalance(%Client{}, %PBFT.UpdataBalanceMessage{}) :: {:ok, %Client{}}
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
