defmodule PBFT do
  @moduledoc """
  An implementation of the PBFT consensus protocol.
  """
  # Shouldn't need to spawn anything from this module, but if you do
  # you should add spawn to the imports.
  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]
    use Cloak.Vault, otp_app: :my_app
  require Fuzzers
  # This allows you to use Elixir's loggers
  # for messages. See
  # https://timber.io/blog/the-ultimate-guide-to-logging-in-elixir/
  # if you are interested in this. Note we currently purge all logs
  # below Info
  require Logger

  # This structure contains all the process state
  # required by the PBFT protocol.
  defstruct(
    # The list of current proceses.
    view: nil,
    # Current primary.
    current_primary: nil,
    # Time before starting an election.
    min_election_timeout: nil,
    max_election_timeout: nil,
    election_timer: nil,
    # Time between heartbeats from the primary.
    heartbeat_timeout: nil,
    heartbeat_timer: nil,
    # Persistent state on all servers.
    current_term: nil,
    voted_for: nil,
    # A short note on log structure: The functions that follow
    # (e.g., get_last_log_index, commit_log_index, etc.) all
    # assume that the log is a list with later entries (i.e.,
    # entries with higher index numbers) appearing closer to
    # the head of the list, and that index numbers start with 1.
    # For example if the log contains 3 entries committe in term
    # 2, 2, and 1 we would expect:
    #
    # `[{index: 3, term: 2, ..}, {index: 2, term: 2, ..},
    #     {index: 1, term: 1}]`
    #
    # If you change this structure, you will need to change
    # those functions.
    #
    # Finally, it might help to know that two lists can be
    # concatenated using `l1 ++ l2`
    log: nil,
    # Volatile state on all servers
    commit_index: nil,
    last_applied: nil,
    # Volatile state on primary
    is_primary: nil,
    next_index: nil,
    match_index: nil,
    # The queue we are building using this RSM.
    queue: nil,
    received_votes: nil,


    # below are added attributes
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
    min_election_timeout,
    max_election_timeout,
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
  min_election_timeout: min_election_timeout,
  max_election_timeout: max_election_timeout,
  heartbeat_timeout: heartbeat_timeout,
  # Start from term 1
  current_term: 1,
  voted_for: nil,
  log: [],
  commit_index: 0,
  last_applied: 0,
  is_primary: false,
  next_index: nil,
  match_index: nil,
  queue: :queue.new(),
  # below are added attributes
  received_votes: nil,
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
      {}

      {:heartbeat_timer, _}->
        prev_log_idx= get_last_log_index(state)
        prev_log_tm= get_last_log_term(state)
        msg=PBFT.AppendEntryRequest.new(
          state.current_term,
          state.current_primary,
          prev_log_idx,
          prev_log_tm,
          nil,
          state.commit_index)
        s1=reset_heartbeat_timer(state)
        IO.puts("primary timer ")
        broadcast_to_others(s1,msg)
        primary(s1,extra_state)

      # Messages from external clients. For all of what follows
      # you should send the `sender` an :ok (see `PBFT.Client`
      # below) only after the request has completed, i.e., after
      # the log entry corresponding to the request has been **committed**.
      {sender, :update_balance} ->
        # TODO: entry is the log entry that you need to
        entry =
          PBFT.LogEntry.update_balance(
            get_last_log_index(state) + 1,
            state.current_term,
            sender
          )

        primary(s1, extra_state)

      {sender, {:new_account, item}} ->
        # TODO: entry is the log entry that you need to
        entry =
          PBFT.LogEntry.new_account(
            get_last_log_index(state) + 1,
            state.current_term,
            sender,
            item
          )
        uniq_seq=generate_unique_sequence(state,extra_state)

        broadcast_to_others(state,uniq_seq)
        # TODO: You might need to update the following call.

        primary(s1, extra_state)



      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        # IO.puts("in 1")
        send(sender, state.queue)
        primary(state, extra_state)

      {sender, :send_log} ->
        # IO.puts("in 2")
        send(sender, state.log)
        primary(state, extra_state)
      {sender,:send_log_length}->
        send(sender,length(state.log))
        primary(state, extra_state)

      {sender, :whois_primary} ->
        # IO.puts("in 3")
        send(sender, {whoami(), state.current_term})
        primary(state, extra_state)

      {sender, :current_process_type} ->
        # IO.puts("in 4")
        send(sender, :primary)
        primary(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        # IO.puts("in 5")
        send(sender, :ok)

        primary(
          %{state | min_election_timeout: min, max_election_timeout: max},
          extra_state
        )

      {sender, {:set_heartbeat_timeout, timeout}} ->
        # IO.puts("in 6")
        state = %{state | heartbeat_timeout: timeout}
        state = reset_heartbeat_timer(state)
        send(sender, :ok)
        primary(state, extra_state)
    end
  end

  @spec replica(%PBFT{is_primary: false}, any()) :: no_return()
  def replica(state, extra_state) do

  end

end
