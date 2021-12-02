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
    my_public_key: nil

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
  @spec broadcast_to_others(any(), any(),any(), any(), any()) :: [boolean()]
  def broadcast_to_others(state, message, prepare_state, commit_state, view \\ nil) do
    me = whoami()
    if view == nil do
      state.view
      |> Enum.filter(fn pid -> pid != me end)
      |> Enum.map(fn pid -> send(pid, message) end)
    else
      view
      |> Enum.filter(fn pid -> pid != me end)
      |> Enum.map(fn pid -> send(pid, message) end)
    end

  end

  @spec initialization(%PBFT{}, [atom()])::[atom()]
  def initialization(state, view_list) do

      ini_msg = PBFT.InitializationMessage.new(nil)
      # Enum.map(view_list ,fn x -> send(x, ini_msg) end)

      view_list
        |> Enum.map(fn x ->
          send(x, ini_msg)
        end)

      queues =
        view_list
        |> Enum.map(fn x ->
          # send(x, ini_msg)
          receive do
            {sender, s} ->
              # IO.puts("ini has received from #{x}")
              {sender, s}
          end
        end)
      IO.puts("this is all keys #{inspect(queues)}")

      Enum.into(queues, %{})
  end

  @doc """
  below is a function that validates the signature.
  """
  @spec validation(%PBFT{}, binary(),any(), atom() ,any(),any()) :: boolean()
  def validation(state,signature, message, sender, prepare_state, commit_state) do
    public = Map.fetch!(state.public_keys_list, sender)
    verify_result = :crypto.verify(:ecdsa, :sha256, message, signature, [public, :secp256k1])
    verify_result
  end

  @doc """
  below is a function that create and sign a signature using the private key.
  """
  @spec authentication(any(),any(),any(),any()) :: binary()
  def authentication(state, message, prepare_state, commit_state) do
    secret=state.my_private_key
    sig = :crypto.sign(:ecdsa, :sha256, message, [secret, :secp256k1])
    sig
  end

  @doc """
  below is a function that make a specific replica the primary
  """
  @spec make_primary(%PBFT{}) :: no_return()
  def make_primary(state) do
    primary(%{state | is_primary: true}, %{}, %{})
  end

  @doc """
  below is a function that checks if the replica had received a pre-prepare message
  for view v and sequence_number n containing a different digest.
  If there is none, then return true, otherwise return false.
  """
  @spec check_v_n(%PBFT{},%PBFT.PrePrepareMessage{},[any()],any(),any()) :: boolean()
  def check_v_n(state, prePrepareMsg, log, prepare_state, commit_state) do
    curr_msg = tl(log)
    if curr_msg.__struct__ ==  prePrepareMsg.__struct__ && curr_msg.view == prePrepareMsg.view && curr_msg.sequence_number == prePrepareMsg.sequence_number && curr_msg.digest != prePrepareMsg.digest do
      false
    end
    if length(log) == 0 do
      true
    else
      check_v_n(state, prePrepareMsg,Enum.take(log,length(log)-1),prepare_state, commit_state)
    end
  end


  @doc """
  below is a function that checks if the digest is the digest for message
  """
  @spec check_d(%PBFT{},any(),any(),any(),any()) :: boolean()
  def check_d(state,digest,message,prepare_state, commit_state) do
    correct_digest=message_digest(state,message,nil,nil)
    if digest == correct_digest do
      true
    else
      false
    end
  end

  @doc """
  below is a function that checks if the sequence_number in the pre-prepare message is between a low water mark sequence_lower_bound and a higher water mark sequence_upper_bound
  """
  @spec check_n(%PBFT{},non_neg_integer(),any(),any()) :: boolean()
  def check_n(state,sequence_number,prepare_state, commit_state) do
    true
  end

  @doc """
  below is a function that adds a messages to different logs
  """
  @spec add_to_log(%PBFT{},any(),any(),any()) :: no_return()
  def add_to_log(state,entry,prepare_state, commit_state) do

      %{state | log: [entry|state.log]}

  end



  @doc """
  below is a function that digests a message, returing the digested message
  """
  @spec message_digest(any(),%PBFT.Message{},any(),any()) :: binary()
  def message_digest(_state, message, prepare_state, commit_state) do
    msg_string=
    to_string(message.op) <>
    to_string(message.name) <>
    to_string(message.amount) <>
    to_string(message.client) <>
    to_string(message.timestamp)
    :crypto.hash(:sha, msg_string)
  end
  @spec primary(%PBFT{is_primary: true}, any(), any()) :: no_return()
  def primary(state, prepare_state, commit_state) do
    # if state.my_public_key != nil do
    #   send(sender, state.my_public_key)
    # end
    receive do
      {sender, %PBFT.RequestMessage{
        timestamp: timestamp,
        message: message,
        signature: signature
      }} ->
        IO.puts("request recieved.")
        digest=message_digest(state, message, prepare_state, commit_state)
        validation_result=true
          # validation(state, signature,digest,sender, prepare_state, commit_state)
        if validation_result==true do
          # sequence_number=generate_unique_sequence(state, prepare_state, commit_state)
          sequence_number=timestamp
          primary_time_stamp=timestamp
          primary_view=length(state.view)


          primary_signature=nil
            # authentication(state, digest,prepare_state, commit_state)
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
        IO.puts("#{whoami()} received Prepare message: [#{view_number}, #{sequence_number}, #{inspect(digest)}, #{id}, #{inspect(signature)}].")
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
        IO.puts("client request recieved.")
        # # validation_result = validation(state, signature, message, sender, extra_state)

        # # if validation_result==true do
        #   sequence_number=generate_unique_sequence(state,prepare_state,commit_state)
        #   # primary_time_stamp=timestamp
        #   primary_view=state.view
        #   primary_signature = nil
        #     # authentication(state, message, extra_state)

        #   digest=message_digest(state, digest, prepare_state,commit_state)
        #   pre_prepare_message=PBFT.PrePrepareMessage.new(primary_view,sequence_number,digest,primary_signature,message)

        #   broadcast_to_others(state,pre_prepare_message,extra_state)
        # # end

      # send(sender, :ok)
      # primary(state, extra_state)

      {sender, %PBFT.InitializationMessage{
        public_key: public_key
      }}->
        state_1 = if public_key==nil do
          {public, secret} = :crypto.generate_key(:ecdh, :secp256k1)
          # state.my_private_key=secret
          # state.my_public_key=public
          state_11 = update_state_attributes(state, :my_private_key, public)
          state_12 = update_state_attributes(state_11, :my_public_key, secret)
          public_key_msg = PBFT.InitializationMessage.new(public)
          _=broadcast_to_others(state, public_key_msg, prepare_state,commit_state)
          _=IO.puts("#{whoami()} has received ini msg")
          _=send(sender, public)
          state_12
        else
          new_key_map = Map.put_new(state.public_keys_list, sender, public_key)

          # IO.puts("received and stored the public key #{inspect(state.public_keys_list)}")
          # update_state_attributes(state, :public_keys_list, new_key_map)
          state_13 = update_state_attributes(state, :public_keys_list, new_key_map)
          IO.puts("received and stored the public key #{inspect(state_13.public_keys_list)}")
          # if length(state.public_keys_list) == state.view do
          if state.my_public_key != nil do
            send(sender, state.my_public_key)
          end
          # end
          state_13

        end
        primary(state_1, prepare_state,commit_state)

    end
  end

  @doc """
    the below function serves as a universal update function for state, you can add more cases
    to it.
  """
  @spec update_state_attributes(%PBFT{}, atom(), any()) :: %PBFT{}
  def update_state_attributes(state, attr_name, value) do
    case attr_name do
      :my_private_key->
      %{state | my_private_key: value}
      :my_public_key->
        %{state | my_public_key: value}
      :public_keys_list->
        %{state | public_keys_list: value}

    end
  end

  @spec make_replica(%PBFT{}) :: no_return()
  def make_replica(state) do
    replica(%{state | is_primary: false}, %{}, %{})
  end

  @spec replica(%PBFT{is_primary: false}, any(), any()) :: no_return()
  def replica(state, prepare_state, commit_state) do
    # if state.my_public_key != nil do
    #   send(sender, state.my_public_key)
    # end
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
        IO.puts("#{whoami()} received Prepare message: [#{view_number}, #{sequence_number}, #{inspect(digest)}, #{inspect(signature)}, #{inspect(message)}].")
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
        IO.puts("#{whoami()} received Prepare message: [#{view_number}, #{sequence_number}, #{inspect(digest)}, #{id}, #{inspect(signature)}].")
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
        #replica(state, prepare_state, commit_state)
        #check signature
        #check previous log
        #check PBFT logic
        #commit
        #send reply
      {sender, %PBFT.RequestMessage{}} ->
        send(sender, {:redirect, state.current_primary})
        replica(state, prepare_state, commit_state)
      {sender, %PBFT.InitializationMessage{
        public_key: public_key
      }}->
        state_1 = if public_key==nil do
          {public, secret} = :crypto.generate_key(:ecdh, :secp256k1)
          # state.my_private_key=secret
          # state.my_public_key=public
          state_11 = update_state_attributes(state, :my_private_key, public)
          state_12 = update_state_attributes(state_11, :my_public_key, secret)
          public_key_msg = PBFT.InitializationMessage.new(public)
          _=broadcast_to_others(state, public_key_msg, prepare_state, commit_state)
          _=send(sender, public)
          _=IO.puts("#{whoami()} has received ini msg")
          state_12
        else
          new_key_map = Map.put_new(state.public_keys_list, sender, public_key)
          state_13 = update_state_attributes(state, :public_keys_list, new_key_map)
          IO.puts("received and stored the public key #{inspect(state_13.public_keys_list)}")
          if state.my_public_key != nil do
            send(sender, state.my_public_key)
          end
          state_13
        end
        replica(state_1, prepare_state, commit_state)
    end

  end

end

defmodule PBFT.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  alias __MODULE__
  @enforce_keys [:primary, :timestamp, :public_keys_list, :my_public_key, :my_private_key]
  defstruct(primary: nil, timestamp: 0, public_keys_list: nil, my_public_key: nil, my_private_key: nil)

  @spec new_client(atom()) :: %Client{primary: atom(), timestamp: integer()}
  def new_client(member) do
    %Client{primary: member, timestamp: 0, public_keys_list: Map.new(), my_public_key: nil, my_private_key: nil}
  end

  @spec set_keys(%Client{}, [atom()], any()):: %Client{}
  def set_keys(state, view, public_keys_list) do
    {public, secret} = :crypto.generate_key(:ecdh, :secp256k1)

    public_key_msg = PBFT.InitializationMessage.new(public)
    _=PBFT.broadcast_to_others(nil, public_key_msg, nil, nil, view)
    %{state | public_keys_list: public_keys_list, my_public_key: public, my_private_key: secret}
  end

  @spec new_account(%Client{}, any(), integer(), atom()) :: {%Client{}}
  def new_account(client, name, amount, client_pid) do
    primary = client.primary
    IO.puts("client timestamp is #{client.timestamp}.")
    client = %{client | timestamp: client.timestamp + 1}
    IO.puts("client timestamp is #{client.timestamp}.")
    message=PBFT.Message.new_account(name, amount, client_pid, client.timestamp)
    message_d = PBFT.message_digest(nil, message, nil, nil)
    sig = nil
      # PBFT.authentication(client, message_d,nil,nil)
    send(primary, %PBFT.RequestMessage{timestamp: client.timestamp,
                                      message: message,
                                      signature: sig})
    IO.puts("Message have been sent to #{inspect(client.primary)}.")
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
    message=PBFT.Message.update_balance(name, amount, client_pid, client.timestamp)
    message_d = PBFT.message_digest(nil, message, nil, nil)
    sig = nil
      # PBFT.authentication(client, message_d,nil,nil)
    send(primary, %PBFT.RequestMessage{timestamp: client.timestamp,
                                      message: message,
                                      signature: sig})
    IO.puts("Message have been sent to #{inspect(client.primary)}.")
    receive do
      {_, :ok} ->
        client
    end
  end
end
