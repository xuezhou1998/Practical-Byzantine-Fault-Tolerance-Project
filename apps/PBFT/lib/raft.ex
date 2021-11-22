defmodule Raft do
  @moduledoc """
  An implementation of the Raft consensus protocol.
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
  # required by the Raft protocol.
  defstruct(
    # The list of current proceses.
    view: nil,
    # Current leader.
    current_leader: nil,
    # Time before starting an election.
    min_election_timeout: nil,
    max_election_timeout: nil,
    election_timer: nil,
    # Time between heartbeats from the leader.
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
    # Volatile state on leader
    is_leader: nil,
    next_index: nil,
    match_index: nil,
    # The queue we are building using this RSM.
    queue: nil,

    # below are added attributes
    received_votes: nil
  )

  @doc """
  Create state for an initial Raft cluster. Each
  process should get an appropriately updated version
  of this state.
  """
  @spec new_configuration(
          [atom()],
          atom(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: %Raft{}
  def new_configuration(
        view,
        leader,
        min_election_timeout,
        max_election_timeout,
        heartbeat_timeout
      ) do
    %Raft{
      view: view,
      current_leader: leader,
      min_election_timeout: min_election_timeout,
      max_election_timeout: max_election_timeout,
      heartbeat_timeout: heartbeat_timeout,
      # Start from term 1
      current_term: 1,
      voted_for: nil,
      log: [],
      commit_index: 0,
      last_applied: 0,
      is_leader: false,
      next_index: nil,
      match_index: nil,
      queue: :queue.new(),
      # below are added attributes
      received_votes: nil
    }
  end

  # Enqueue an item, this **modifies** the state
  # machine, and should only be called when a log
  # entry is committed.
  @spec enqueue(%Raft{}, any()) :: %Raft{}
  defp enqueue(state, item) do
    # IO.puts("ENQUE item #{inspect(item)}")
    %{state | queue: :queue.in(item, state.queue)}
  end

  # Dequeue an item, modifying the state machine.
  # This function should only be called once a
  # log entry has been committed.
  @spec dequeue(%Raft{}) :: {:empty | {:value, any()}, %Raft{}}
  defp dequeue(state) do
    {ret, queue} = :queue.out(state.queue)
    {ret, %{state | queue: queue}}
  end

  @doc """
  Commit a log entry, advancing the state machine. This
  function returns a tuple:
  * The first element is {requester, return value}. Your
    implementation should ensure that the leader who committed
    the log entry sends the return value to the requester.
  * The second element is the updated state.
  """
  @spec commit_log_entry(%Raft{}, %Raft.LogEntry{}) ::
          {{atom() | pid(), :ok | :empty | {:value, any()}}, %Raft{}}
  def commit_log_entry(state, entry) do
    case entry do
      %Raft.LogEntry{operation: :nop, requester: r, index: i} ->
        {{r, :ok}, %{state | commit_index: i}}

      %Raft.LogEntry{operation: :enq, requester: r, argument: e, index: i} ->
        {{r, :ok}, %{enqueue(state, e) | commit_index: i}}

      %Raft.LogEntry{operation: :deq, requester: r, index: i} ->
        {ret, state} = dequeue(state)
        {{r, ret}, %{state | commit_index: i}}

      %Raft.LogEntry{} ->
        raise "Log entry with an unknown operation: maybe an empty entry?"

      _ ->
        raise "Attempted to commit something that is not a log entry."
    end
  end

  @doc """
  Commit log at index `index`. This index, which one should read from
  the log entry is assumed to start at 1. This function **does not**
  ensure that commits are processed in order.
  """
  @spec commit_log_index(%Raft{}, non_neg_integer()) ::
          {:noentry | {atom(), :ok | :empty | {:value, any()}}, %Raft{}}
  def commit_log_index(state, index) do
    if length(state.log) < index do
      # IO.puts("commited nothing")
      {:noentry, state}
    else
      # Note that entry indexes are all 1, which in
      # turn means that we expect commit indexes to
      # be 1 indexed. Now a list is a reversed log,
      # so what we can do here is simple:
      # Given 0-indexed index i, length(log) - 1 - i
      # is the ith list element. => length(log) - (i +1),
      # and hence length(log) - index is what we want.
      correct_idx = length(state.log) - index
      commit_log_entry(state, Enum.at(state.log, correct_idx))
    end
  end

  # The next few functions are public so we can test them, see
  # log_test.exs.
  @doc """
  Get index for the last log entry.
  """
  @spec get_last_log_index(%Raft{}) :: non_neg_integer()
  def get_last_log_index(state) do
    Enum.at(state.log, 0, Raft.LogEntry.empty()).index
  end

  @doc """
  Get term for the last log entry.
  """
  @spec get_last_log_term(%Raft{}) :: non_neg_integer()
  def get_last_log_term(state) do
    Enum.at(state.log, 0, Raft.LogEntry.empty()).term
  end

  @doc """
  Check if log entry at index exists.
  """
  @spec logged?(%Raft{}, non_neg_integer()) :: boolean()
  def logged?(state, index) do
    index > 0 && length(state.log) >= index
  end

  @doc """
  Get log entry at `index`.
  """
  @spec get_log_entry(%Raft{}, non_neg_integer()) ::
          :noentry | %Raft.LogEntry{}
  # original atom was :no_entry
  def get_log_entry(state, index) do
    if index <= 0 || length(state.log) < index do
      :noentry
    else
      # Note that entry indexes are all 1, which in
      # turn means that we expect commit indexes to
      # be 1 indexed. Now a list is a reversed log,
      # so what we can do here is simple:
      # Given 0-indexed index i, length(log) - 1 - i
      # is the ith list element. => length(log) - (i +1),
      # and hence length(log) - index is what we want.
      correct_idx = length(state.log) - index
      Enum.at(state.log, correct_idx)
    end
  end

  @doc """
  Get log entries starting at index.
  """
  @spec get_log_suffix(%Raft{}, non_neg_integer()) :: [%Raft.LogEntry{}]
  def get_log_suffix(state, index) do
    if length(state.log) < index do
      []
    else
      correct_idx = length(state.log) - index
      Enum.take(state.log, correct_idx + 1)
    end
  end

  @doc """
  Truncate log entry at `index`. This removes log entry
  with index `index` and larger.
  """
  @spec truncate_log_at_index(%Raft{}, non_neg_integer()) :: %Raft{}
  def truncate_log_at_index(state, index) do
    if length(state.log) < index do
      # Nothing to do
      state
    else
      to_drop = length(state.log) - index + 1
      %{state | log: Enum.drop(state.log, to_drop)}
    end
  end

  @doc """
  Add log entries to the log. This adds entries to the beginning
  of the log, we assume that entries are already correctly ordered
  (see structural note about log above.).
  """
  @spec add_log_entries(%Raft{}, [%Raft.LogEntry{}]) :: %Raft{}
  def add_log_entries(state, entries) do
    %{state | log: entries ++ state.log}
  end

  @doc """
  make_leader changes process state for a process that
  has just been elected leader.
  """
  @spec make_leader(%Raft{}) :: %Raft{
          is_leader: true,
          next_index: map(),
          match_index: map()
        }
  def make_leader(state) do
    log_index = get_last_log_index(state)

    # next_index needs to be reinitialized after each
    # election.
    next_index =
      state.view
      |> Enum.map(fn v -> {v, log_index} end)
      # |> Enum.map(fn v -> {v, log_index} end) <<<<<<<<<<<< original code
      |> Map.new()

    # match_index needs to be reinitialized after each
    # election.
    match_index =
      state.view
      |> Enum.map(fn v -> {v, 0} end)
      |> Map.new()

    %{
      state
      | is_leader: true,
        next_index: next_index,
        match_index: match_index,
        current_leader: whoami()
    }
  end

  @doc """
  make_follower changes process state for a process
  to mark it as a follower.
  """
  @spec make_follower(%Raft{}) :: %Raft{
          is_leader: false
        }
  def make_follower(state) do
    %{state | is_leader: false}
  end

  # update_leader: update the process state with the
  # current leader
  @spec update_leader(%Raft{}, atom()) :: %Raft{current_leader: atom()}
  defp update_leader(state, who) do
    %{state | current_leader: who}
  end

  # Compute a random election timeout between
  # state.min_election_timeout and state.max_election_timeout.
  # See the paper to understand the reasoning behind having
  # a randomized election timeout.
  @spec get_election_time(%Raft{}) :: non_neg_integer()
  defp get_election_time(state) do
    state.min_election_timeout +
      :rand.uniform(
        state.max_election_timeout -
          state.min_election_timeout
      )
  end

  # Save a handle to the election timer.
  @spec save_election_timer(%Raft{}, reference()) :: %Raft{}
  defp save_election_timer(state, timer) do
    %{state | election_timer: timer}
  end

  # Save a handle to the hearbeat timer.
  @spec save_heartbeat_timer(%Raft{}, reference()) :: %Raft{}
  defp save_heartbeat_timer(state, timer) do
    %{state | heartbeat_timer: timer}
  end

  # Utility function to send a message to all
  # processes other than the caller. Should only be used by leader.
  #<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # this is the original specification:
  # @spec broadcast_to_others(%Raft{is_leader: true}, any()) :: [boolean()]
  @spec broadcast_to_others(%Raft{}, any()) :: [boolean()]
  defp broadcast_to_others(state, message) do
    me = whoami()

    state.view
    |> Enum.filter(fn pid -> pid != me end)
    |> Enum.map(fn pid -> send(pid, message) end)
  end

  # END OF UTILITY FUNCTIONS. You should not need to (but are allowed to)
  # change any of the code above this line, but will definitely need to
  # change the code that follows.

  # This function should cancel the current
  # election timer, and set  a new one. You can use
  # `get_election_time` defined above to get a
  # randomized election timeout. You might need
  # to call this function from within your code.
  @spec reset_election_timer(%Raft{}) :: %Raft{}
  defp reset_election_timer(state) do
    # TODO: Set a new election timer
    # You might find `save_election_timer` of use.
    # raise "Not yet implemented"
    tmr=state.election_timer
    if tmr != nil do
      _ret=Emulation.cancel_timer(tmr)
    end

    rd_ele_time=get_election_time(state)
    tmer=Emulation.timer(rd_ele_time,:election_timer)
    save_election_timer(state,tmer)
  end

  # This function should cancel the current
  # hearbeat timer, and set  a new one. You can
  # get heartbeat timeout from `state.heartbeat_timeout`.
  # You might need to call this from your code.
  @spec reset_heartbeat_timer(%Raft{}) :: %Raft{}
  defp reset_heartbeat_timer(state) do
    # TODO: Set a new heartbeat timer.
    # You might find `save_heartbeat_timer` of use.
    # raise "Not yet implemented"
    tmr=state.heartbeat_timer
    if tmr !=nil do
      _ret=Emulation.cancel_timer(tmr)
    end

    tmer=Emulation.timer(state.heartbeat_timeout, :heartbeat_timer)
    save_heartbeat_timer(state, tmer)
  end

  @doc """
  This function transitions a process so it is
  a follower.
  """
  @spec become_follower(%Raft{}) :: no_return()
  def become_follower(state) do
    # TODO: Do anything you need to when a process
    # transitions to a follower.
    # raise "Not yet implemented."
    s=reset_heartbeat_timer(state)
    follower(make_follower(s), nil)
  end

  @spec compare_two_entries([any()],[any()])::integer()
  def compare_two_entries(currentEntries, entries) do

    # ce_list=Enum.map(currentEntries, &get_entry_index/1)
    # e_list=Enum.map(entries, &get_entry_index/1)
    # # Enum.reduce()
    res=
    for x <- currentEntries do
      lst=
      for y <- entries do
        # {a,_v}=List.pop_at(entries)
        if y.index==x.index && y.term != x.term do
          1
        else
          0
        end
      end
      Enum.sum(lst)
    end
    Enum.sum(res)

  end

  @spec get_entry_index(%Raft.LogEntry{}) :: any()
  def get_entry_index (entry) do
    {entry.index , entry.term}
  end

  # @spec compare_one_to_mul([%Raft.LogEntry{}],%Raft.LogEntry{}) :: boolean()

  @spec get_log_suffix_sender([any()], non_neg_integer()) :: [%Raft.LogEntry{}]
  def get_log_suffix_sender(entries, index) do
    if length(entries) < index do
      []
    else
      correct_idx = length(entries) - index
      Enum.take(entries, correct_idx + 1)
    end
  end
  @spec update_log_commit_index(%Raft{}, non_neg_integer()) :: %Raft{}
  def update_log_commit_index(state, index) do
    %{state | commit_index: index}
  end
  @spec update_last_applied(%Raft{}, non_neg_integer()) :: %Raft{}
  def update_last_applied(state, index) do
    %{state | last_applied: index}
  end
  @spec update_next_index(%Raft{},atom() ,non_neg_integer()) :: %Raft{}
  def update_next_index(state, server,index) do
    k=state.next_index

    next_idx=Map.replace(k,server,index)
    %{state | next_index: next_idx}
  end
  @spec update_match_index(%Raft{},atom(), non_neg_integer()) :: %Raft{}
  def update_match_index(state,server, index) do
    k=state.match_index
    match_idx=Map.replace(k,server,index)
    %{state | match_index: match_idx}
  end
  @spec update_current_term(%Raft{},non_neg_integer()) :: %Raft{}
  def update_current_term(state,new_term) do
    %{state | current_term: new_term}
  end
  @spec check_up_to_date(%Raft{},non_neg_integer(),non_neg_integer()) :: boolean()
  def check_up_to_date(state, last_idx,last_tm) do
    my_last_idx=get_last_log_index(state)
    my_last_tm=get_last_log_term(state)
    cond do
       last_tm != my_last_tm ->
        if last_tm >= my_last_tm do
          true
        else
          false
        end
     last_tm == my_last_tm ->
        if last_idx >= my_last_idx do
          true
        else
          false
        end

    end
  end


  @doc """
  This function implements the state machine for a process
  that is currently a follower.

  `extra_state` can be used to hod anything that you find convenient
  when building your implementation.
  """
  @spec follower(%Raft{is_leader: false}, any()) :: no_return()
  def follower(state, extra_state) do
    receive do
      # Messages that are a part of Raft.
      {sender,
        %Raft.AppendEntryRequest{
          term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: nil,
         leader_commit_index: leader_commit_index
        }
      }->
        s=reset_election_timer(state)
        follower(s,extra_state)
      {_,:election_timer}->
        ## election timeout

        become_candidate(state)


      {sender,
       %Raft.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }
       } ->
         # TODO: Handle an AppendEntryRequest received by a
        me = whoami()
        myPrevEntry = get_log_entry(state, prev_log_index)
        myprevterm = if myPrevEntry != :noentry do
            myPrevEntry.term
        else
          0
        end
        back_index = prev_log_index
        mysuccess = if term<state.current_term || myprevterm != prev_log_term do
          false
        else
          true
        end
        state=if mysuccess==true do
          minIdxBegin=state.commit_index  ### - leader_com_idx
          f_suffix=get_log_suffix(state, state.commit_index+1)

          truncate_index=compare_two_entries(f_suffix,entries)
          s1=if truncate_index>0 do
            truncate_log_at_index(state, prev_log_index+1 ) ##originally truncate index
          else
            state
          end
          # append_idx=max(truncate_index,minIdxBegin+1)

          # IO.puts("entries len: #{inspect(length(entries))} append #{inspect(append_idx)}, truncate #{inspect(truncate_index)}, minIdxBegin #{inspect(minIdxBegin)} #{inspect(me)}")
          # may have doubts for the above line

          # append_entries=get_log_suffix_sender(entries,append_idx)
          last_idx_f=get_last_log_index(s1)
          entries_uniq=
            for x <- entries do
              if x.index != last_idx_f do
                x
              end
            end
          entries_nnil=Enum.filter(entries_uniq, & !is_nil(&1))
          entries_uniq_reversed=Enum.reverse(entries_nnil)
          # IO.puts("ER #{inspect(entries_uniq_reversed)}")
          s2=add_log_entries(s1,entries_uniq_reversed)
          # IO.puts("executed add entries: #{inspect(append_entries)} #{inspect(me)}")
          latestIdx=get_last_log_index(s2)
          s3=if leader_commit_index>s2.commit_index do
            update_log_commit_index(s2,min(leader_commit_index,latestIdx))
          else
            s2
          end
          back_index=get_last_log_index(s3) ####################### changed from lastidx
          # {pa,pb,pc } = {s3.current_term,back_index,mysuccess}
          resp=Raft.AppendEntryResponse.new(s3.current_term,back_index,mysuccess)
          send(sender,resp)
          s3
        else
          # {pa,pb,pc } = {state.current_term,back_index,mysuccess}
          resp=Raft.AppendEntryResponse.new(state.current_term,back_index,mysuccess)
          send(sender,resp)
          state
        end
        state= if state.commit_index>state.last_applied do
          s=update_last_applied(state,state.last_applied+1)
          {_v,s}=commit_log_index(s,s.last_applied)
          s
        else
          state
        end
        follower(state, extra_state)


      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        # TODO: Handle an AppendEntryResponse received by
        # a follower.
        IO.puts(
          "Follower received append entry response #{term}," <>
            " index #{index}, succcess #{inspect(succ)}"
        )

        raise "Not yet implemented"

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote call received by a
        # follower.
        IO.puts(
          "Follower received RequestVote " <>
            "term = #{term}, candidate = #{candidate}"
        )

        # raise "Not yet implemented"
        reply =
          if term < state.current_term do
            false
          else
            if state.voted_for== candidate || state.voted_for==nil do
              res = check_up_to_date(state, last_log_index, last_log_term)
              if res == true do
                true
              else
                false
              end
            end
          end
        s1 = update_voted_for(state, candidate)
        msg = Raft.RequestVoteResponse.new(reply, s1.current_term)
        send(sender, msg)
        follower(s1, extra_state)


      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle a RequestVoteResponse.
        IO.puts(
          "Follower received RequestVoteResponse " <>
            "term = #{term}, granted = #{inspect(granted)}"
        )

        raise "Not yet implemented"

      # Messages from external clients. In each case we
      # tell the client that it should go talk to the
      # leader.
      {sender, :nop} ->
        send(sender, {:redirect, state.current_leader})
        follower(state, extra_state)

      {sender, {:enq, item}} ->
        send(sender, {:redirect, state.current_leader})
        follower(state, extra_state)

      {sender, :deq} ->
        send(sender, {:redirect, state.current_leader})
        follower(state, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        send(sender, state.queue)
        follower(state, extra_state)

      {sender, :send_log} ->
        send(sender, state.log)
        follower(state, extra_state)
      {sender,:send_log_length}->
        send(sender,length(state.log))
        follower(state, extra_state)
      {sender, :whois_leader} ->
        send(sender, {state.current_leader, state.current_term})
        follower(state, extra_state)

      {sender, :current_process_type} ->
        send(sender, :follower)
        follower(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        state = %{state | min_election_timeout: min, max_election_timeout: max}
        state = reset_election_timer(state)
        send(sender, :ok)
        follower(state, extra_state)

      {sender, {:set_heartbeat_timeout, timeout}} ->
        send(sender, :ok)
        follower(%{state | heartbeat_timeout: timeout}, extra_state)
    end
  end

  @doc """
  This function transitions a process that is not currently
  the leader so it is a leader.
  """
  @spec become_leader(%Raft{is_leader: false}) :: no_return()
  def become_leader(state) do
    # TODO: Send out any one time messages that need to be sent,
    # you might need to update the call to leader too.
    # raise "Not yet implemented"
    me=whoami()
    term=state.current_term
    prev_log_idx=get_last_log_index(state)
    prev_log_tm=get_last_log_term(state)
    leader_cmmt=state.commit_index
    s=reset_heartbeat_timer(state)
    msg= Raft.AppendEntryRequest.new(term,me,prev_log_idx,prev_log_tm,nil,leader_cmmt)
    broadcast_to_others(s, msg)
    leader(make_leader(s), nil)
  end

  @spec create_extra_state(atom()) :: %{}
  def create_extra_state(client) do
    %{client: client, append_entries_map: %{}}
  end
  @spec check_n(%Raft{is_leader: true},[any()], non_neg_integer() ,non_neg_integer() , non_neg_integer(), non_neg_integer() ) :: integer()
  def check_n(state,match_idx_keys, n, last_idx,trues,majority) do

    if n>last_idx do
      -1
    else
      res= check_n_sub(state,match_idx_keys, n,0,majority)
      if res <0 do
        check_n(state,match_idx_keys, n+1, last_idx,0,majority)
      else
        res
      end
    end
  end
  @spec check_n_sub(%Raft{is_leader: true},[any()] , non_neg_integer() ,non_neg_integer() , non_neg_integer() ) :: integer()
  def check_n_sub(state,match_idx_keys, n,trues,majority) do
    cond do
      trues >= majority ->
        n
      length(match_idx_keys)<=0 ->
        -1
      true ->
        {k,lst}=List.pop_at(match_idx_keys,0)
        ln=get_log_entry(state,n).term
        if (state.match_index[k] >= n) && (ln==state.current_term) && (k != state.current_leader) do

          check_n_sub(state,lst, n,trues+1,majority)
        else
          check_n_sub(state,lst, n,trues,majority)
        end
    end
  end

  @doc """
  This function implements the state machine for a process
  that is currently the leader.

  `extra_state` can be used to hold any additional information.
  HINT: It might be useful to track the number of responses
  received for each AppendEntry request.
  """
  @spec leader(%Raft{is_leader: true}, any()) :: no_return()
  def leader(state, extra_state) do

    receive do
      # Messages that are a part of Raft.
      {sender,
       %Raft.AppendEntryRequest{
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
        # TODO: Handle an AppendEntryRequest seen by the leader.

        IO.puts(
          "Leader Received append entry for term #{term} with leader #{
            leader_id
          } " <>
            "(#{leader_commit_index})"
        )

      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        ss1=if succ==true do
        {u,v}=Map.fetch(state.next_index,sender)
        # leader_last_log_idx=get_last_log_index(state)
        s1=update_next_index(state,sender,index+1)
        s1=update_match_index(s1,s1.current_leader,index)
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
          msg = Raft.AppendEntryRequest.new(s2.current_term,s2.current_leader,index-1, prev_log_tm,suffix, s2.commit_index   )
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
        leader(ss3, extra_state)

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote call at the leader.
        IO.puts(
          "Leader received RequestVote " <>
            "term = #{term}, candidate = #{candidate}"
        )
        raise "Not yet implemented"

      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle RequestVoteResponse at a leader.
        IO.puts(
          "Leader received RequestVoteResponse " <>
            "term = #{term}, granted = #{inspect(granted)}"
        )
        raise "Not yet implemented"

      {:heartbeat_timer, _}->
        prev_log_idx= get_last_log_index(state)
        prev_log_tm= get_last_log_term(state)
        msg=Raft.AppendEntryRequest.new(
          state.current_term,
          state.current_leader,
          prev_log_idx,
          prev_log_tm,
          nil,
          state.commit_index)
        s1=reset_heartbeat_timer(state)
        IO.puts("leader timer ")
        broadcast_to_others(s1,msg)
        leader(s1,extra_state)

      # Messages from external clients. For all of what follows
      # you should send the `sender` an :ok (see `Raft.Client`
      # below) only after the request has completed, i.e., after
      # the log entry corresponding to the request has been **committed**.
      {sender, :nop} ->
        # TODO: entry is the log entry that you need to
        entry =
          Raft.LogEntry.nop(
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
            if last_idx >= x && k != s1.current_leader do
              # IO.puts("to send log len #{inspect(length(state.log))} nop #{x}")
              suffix=get_log_suffix(s1,x)
              # IO.puts("to send suf len #{inspect(length(suffix))} nop #{x}")
              send(k,Raft.AppendEntryRequest.new(
                s1.current_term,
                s1.current_leader,
                prev_log_idx,
                prev_log_tm,
                suffix,
                s1.commit_index)
               )
            end
          end
        # TODO: You might need to update the following call.
        extra_state=create_extra_state(sender)
        leader(s1, extra_state)

      {sender, {:enq, item}} ->
        # TODO: entry is the log entry that you need to
        entry =
          Raft.LogEntry.enqueue(
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
            if last_idx >= x && k != s1.current_leader do
              # IO.puts("to send log len #{inspect(length(state.log))} nop #{x}")
              suffix=get_log_suffix(s1,x)
              # IO.puts("to send suf len #{inspect(length(suffix))} nop #{x}")
              send(k,Raft.AppendEntryRequest.new(
                s1.current_term,
                s1.current_leader,
                prev_log_idx,
                prev_log_tm,
                suffix,
                s1.commit_index)
               )
            end
          end
        # TODO: You might need to update the following call.
        extra_state=create_extra_state(sender)
        leader(s1, extra_state)

      {sender, :deq} ->
        # TODO: entry is the log entry that you need to
        entry =
          Raft.LogEntry.dequeue(
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
            if last_idx >= x && k != s1.current_leader do
              # IO.puts("to send log len #{inspect(length(state.log))} nop #{x}")
              suffix=get_log_suffix(s1,x)
              # IO.puts("to send suf len #{inspect(length(suffix))} nop #{x}")
              send(k,Raft.AppendEntryRequest.new(
                s1.current_term,
                s1.current_leader,
                prev_log_idx,
                prev_log_tm,
                suffix,
                s1.commit_index)
               )
            end
          end
        # TODO: You might need to update the following call.
        extra_state=create_extra_state(sender)
        leader(s1, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        # IO.puts("in 1")
        send(sender, state.queue)
        leader(state, extra_state)

      {sender, :send_log} ->
        # IO.puts("in 2")
        send(sender, state.log)
        leader(state, extra_state)
      {sender,:send_log_length}->
        send(sender,length(state.log))
        leader(state, extra_state)

      {sender, :whois_leader} ->
        # IO.puts("in 3")
        send(sender, {whoami(), state.current_term})
        leader(state, extra_state)

      {sender, :current_process_type} ->
        # IO.puts("in 4")
        send(sender, :leader)
        leader(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        # IO.puts("in 5")
        send(sender, :ok)

        leader(
          %{state | min_election_timeout: min, max_election_timeout: max},
          extra_state
        )

      {sender, {:set_heartbeat_timeout, timeout}} ->
        # IO.puts("in 6")
        state = %{state | heartbeat_timeout: timeout}
        state = reset_heartbeat_timer(state)
        send(sender, :ok)
        leader(state, extra_state)
    end

  end

  @doc """
  This function transitions a process to candidate.
  """
  @spec become_candidate(%Raft{is_leader: false}) :: no_return()
  def become_candidate(state) do
    # TODO:   Send out any messages that need to be sent out
    # you might need to update the call to candidate below.
    # raise "Not yet implemented"


    crr_term=state.current_term+1
    s1=update_current_term(state, crr_term)
    crr_tm=s1.current_term

    me=whoami()
    s2=update_voted_for(s1,me)

    s3=reset_election_timer(s2)

    last_idx=get_last_log_index(s3)
    last_tm=get_last_log_term(s3)
    msg=Raft.RequestVote.new(crr_tm,me,last_idx,last_tm)
    _res=broadcast_to_others(s3,msg)

    make_candidate(s3)
  end

  @spec update_voted_for(%Raft{}, atom()) :: %Raft{}
  def update_voted_for(state, who) do
    %{state | voted_for: who}
  end

  @spec make_candidate(%Raft{}) :: %Raft{}
  def make_candidate(state) do
   # maintain votes received by the candadite
    received_votes_lst =
      state.view
      |> Enum.map(fn v -> {v, false } end)
      |> Map.new()
    %{
      state
      | is_leader: false,
        received_votes: received_votes_lst}
  end

  @spec update_received_votes(%Raft{},atom(),boolean()) :: %Raft{}
  def update_received_votes(state, who, vote_value) do
    k=state.received_votes
    receive_votes=Map.replace(k,who, vote_value)
    %{state | receive_votes: receive_votes}
  end
  @spec count_receive_votes(%Raft{})::%Raft{}
  def count_receive_votes(state) do
    k= state.received_votes
    ret = Enum.reduce(k, 0, fn {_server, vote}, sum ->
      if vote== true, do: sum + 1, else: sum
    end)
    ret
  end
  @doc """
  This function implements the state machine for a process
  that is currently a candidate.

  `extra_state` can be used to store any additional information
  required, e.g., to count the number of votes received.
  """
  @spec candidate(%Raft{is_leader: false}, any()) :: no_return()
  def candidate(state, extra_state) do
    receive do

      {sender,
       %Raft.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }} ->
        # TODO: Handle an AppendEntryRequest as a candidate
        IO.puts(
          "Candidate received append entry for term #{term} " <>
            "with leader #{leader_id} " <>
            "(#{leader_commit_index})"
        )
        if entries==nil do
          if term >= state.current_term do
            s11=update_leader(state,sender)
            s12=update_current_term(s11,term)
            become_follower(s12)
          else
            candidate(state, extra_state)
          end
        else
          if term>state.current_term do
            s11=update_leader(state,sender)
            s12=update_current_term(s11,term)
            become_follower(s12)
          else
            candidate(state, extra_state)
          end

        end


      {_,:election_timer}->
        # raise "Not yet implemented"
        s1=reset_election_timer(state)
        candidate(s1, extra_state)
      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        # TODO: Handle an append entry response as a candidate
        IO.puts(
          "Candidate received append entry response #{term}," <>
            " index #{index}, succcess #{succ}"
        )

        raise "Not yet implemented"

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote response as a candidate.
        IO.puts(
          "Candidate received RequestVote " <>
            "term = #{term}, candidate = #{candidate}"
        )

        raise "Not yet implemented"

      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle a RequestVoteResposne as a candidate.
        IO.puts(
          "Candidate received RequestVoteResponse " <>
            "term = #{term}, granted = #{inspect(granted)}"
        )

        # raise "Not yet implemented"
        s1 = if granted==true do
          update_received_votes(state, sender, true)
        else
          update_received_votes(state, sender, false)
        end
        vote_count = count_receive_votes(s1)
        view=s1.view
        majority= div(length(view),2) + 1
        if vote_count >= majority do
          become_leader(s1)
        else
          candidate(s1,extra_state)
        end


      # Messages from external clients.
      {sender, :nop} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      {sender, {:enq, item}} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      {sender, :deq} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        send(sender, state.queue)
        candidate(state, extra_state)

      {sender, :send_log} ->
        send(sender, state.log)
        candidate(state, extra_state)
      {sender,:send_log_length}->
        send(sender,length(state.log))
        candidate(state, extra_state)
      {sender, :whois_leader} ->
        send(sender, {:candidate, state.current_term})
        candidate(state, extra_state)

      {sender, :current_process_type} ->
        send(sender, :candidate)
        candidate(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        state = %{state | min_election_timeout: min, max_election_timeout: max}
        state = reset_election_timer(state)
        send(sender, :ok)
        candidate(state, extra_state)

      {sender, {:set_heartbeat_timeout, timeout}} ->
        send(sender, :ok)
        candidate(%{state | heartbeat_timeout: timeout}, extra_state)
    end
  end
end

defmodule Raft.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to the RSM.
  """
  alias __MODULE__
  @enforce_keys [:leader]
  defstruct(leader: nil)

  @doc """
  Construct a new Raft Client. This takes an ID of
  any process that is in the RSM. We rely on
  redirect messages to find the correct leader.
  """
  @spec new_client(atom()) :: %Client{leader: atom()}
  def new_client(member) do
    %Client{leader: member}
  end

  @doc """
  Send a nop request to the RSM.
  """
  @spec nop(%Client{}) :: {:ok, %Client{}}
  def nop(client) do
    leader = client.leader
    send(leader, :nop)

    receive do
      {_, {:redirect, new_leader}} ->
        nop(%{client | leader: new_leader})

      {_, :ok} ->
        {:ok, client}
    end
  end

  @doc """
  Send a dequeue request to the RSM.
  """
  @spec deq(%Client{}) :: {:empty | {:value, any()}, %Client{}}
  def deq(client) do
    leader = client.leader
    send(leader, :deq)

    receive do
      {_, {:redirect, new_leader}} ->
        deq(%{client | leader: new_leader})

      {_, v} ->
        {v, client}
    end
  end

  @doc """
  Send an enqueue request to the RSM.
  """
  @spec enq(%Client{}, any()) :: {:ok, %Client{}}
  def enq(client, item) do
    leader = client.leader
    send(leader, {:enq, item})

    receive do
      {_, :ok} ->
        {:ok, client}

      {_, {:redirect, new_leader}} ->
        enq(%{client | leader: new_leader}, item)
    end
  end
end
