defmodule PBFT do
  @moduledoc """
  An implementation of the PBFT consensus protocol.
  """
  # Shouldn't need to spawn anything from this module, but if you do
  # you should add spawn to the imports.
  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

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
    account_book: nil
  )
  @spec new_configuration(
    [atom()],
    atom(),
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer()
  ) :: %PBFT{}
  def new_configuration(
    view,
    primary,
    min_election_timeout,
    max_election_timeout,
    heartbeat_timeout,
    sequence_upper_bound,
    sequence_lower_bound
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
    sequence_upper_bound: nil,
    sequence_lower_bound: nil,
    account_book: MapSet.new()
  }
  end


  @spec generate_unique_sequence(%PBFT{is_primary: true}, any()) :: integer()
  def generate_unique_sequence(state, extra_state) do
    0
  end

  @spec validation(%PBFT{is_primary: true},any(),[atom()],non_neg_integer(),any() ) :: boolean()
  def validation(state,digest_of_message,view,sequence_number,signature) do
    true
  end
  @spec primary(%PBFT{is_primary: true}, any()) :: no_return()
  def primary(state, extra_state) do
    receive do
      # Messages that are a part of PBFT.
      {sender,
       %PBFT.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }} ->
        if term> state.current_term do
          # s1=make_follower(state)
          s1=update_current_term(state,term)
          become_follower(s1)
        end
        # TODO: Handle an AppendEntryRequest seen by the primary.

        IO.puts(
          "primary Received append entry for term #{term} with primary #{
            leader_id
          } " <>
            "(#{leader_commit_index})"
        )

      {sender,
       %PBFT.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        ss1=if succ==true do
        {u,v}=Map.fetch(state.next_index,sender)
        # leader_last_log_idx=get_last_log_index(state)
        s1=update_next_index(state,sender,index+1)
        s1=update_match_index(s1,s1.current_primary,index)
        s1=update_match_index(s1,sender,index)
        s1
        else
          next_idx_key=state.next_index
          {_u,v} = Map.fetch(next_idx_key,sender)
          k=state
          s2=update_next_index(k,sender,v-1)
          next_idx_key=s2.next_index
          {_u,decre_next_index} = Map.fetch(next_idx_key,sender)
          suffix = get_log_suffix(s2,decre_next_index)
          prev_log_tm = get_log_entry(s2,index-1).term
          msg = PBFT.AppendEntryRequest.new(s2.current_term,s2.current_primary,index-1, prev_log_tm,suffix, s2.commit_index   )
          send(sender, msg)
          s2
        end
        last_idx=get_last_log_index(ss1)
        k=ss1.match_index
        kk=Map.keys(k)
        maj=div(length(kk),2)+1
        res = check_n(ss1,kk,ss1.commit_index+1,last_idx,0,maj)
        ss2 = if res >= 0 do
          update_log_commit_index(ss1,res )
        else
          ss1
        end
        ss3 = if ss2.commit_index>ss2.last_applied do
          s=update_last_applied(ss2,ss2.last_applied+1)
          {v,sr2}=commit_log_entry(s,get_log_entry(s,s.last_applied))
          {client_name,return_val}=v
          send(client_name,return_val)
          sr2
        else
          ss2
        end
        primary(ss3, extra_state)

      {sender,
       %PBFT.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote call at the primary.
        IO.puts(
          "primary received RequestVote " <>
            "term = #{term}, candidate = #{candidate}"
        )
        raise "Not yet implemented"

      {sender,
       %PBFT.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle RequestVoteResponse at a primary.
        IO.puts(
          "primary received RequestVoteResponse " <>
            "term = #{term}, granted = #{inspect(granted)}"
        )
        raise "Not yet implemented"

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
          prev_log_idx= get_last_log_index(state)
          prev_log_tm= get_last_log_term(state)
          entryList=[entry]
          s1=add_log_entries(state,entryList)

          last_idx=get_last_log_index(s1)
          for {k,x} <- s1.next_index do
            if last_idx >= x && k != s1.current_primary do
              # IO.puts("to send log len #{inspect(length(state.log))} update_balance #{x}")
              suffix=get_log_suffix(s1,x)
              # IO.puts("to send suf len #{inspect(length(suffix))} update_balance #{x}")
              send(k,PBFT.AppendEntryRequest.new(
                s1.current_term,
                s1.current_primary,
                prev_log_idx,
                prev_log_tm,
                suffix,
                s1.commit_index)
               )
            end
          end
        # TODO: You might need to update the following call.
        extra_state=create_extra_state(sender)
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
          prev_log_idx= get_last_log_index(state)
          prev_log_tm= get_last_log_term(state)
          entryList=[entry]
          s1=add_log_entries(state,entryList)

          last_idx=get_last_log_index(s1)
          for {k,x} <- s1.next_index do
            if last_idx >= x && k != s1.current_primary do
              # IO.puts("to send log len #{inspect(length(state.log))} update_balance #{x}")
              suffix=get_log_suffix(s1,x)
              # IO.puts("to send suf len #{inspect(length(suffix))} update_balance #{x}")
              send(k,PBFT.AppendEntryRequest.new(
                s1.current_term,
                s1.current_primary,
                prev_log_idx,
                prev_log_tm,
                suffix,
                s1.commit_index)
               )
            end
          end
        # TODO: You might need to update the following call.
        extra_state=create_extra_state(sender)
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
