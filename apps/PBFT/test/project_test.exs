IO.puts("this is a project test")
defmodule ProjectTest do
  use ExUnit.Case
  doctest PBFT

  defp print_a do
    PBFT.new_configuration([:a, :b, :c, :d], :a, 100, 1000, 20, [], 100, 1000)
    IO.puts("this is a project test function")
    PBFT.test_function()
  end

  test "simple project test" do
    print_a()
    IO.puts("this is a simple test")
  end

  import Emulation, only: [spawn: 2, send: 2, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "client creation" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(2)])

    my_view=[:a, :b, :c, :d]

    base_config =
      PBFT.new_configuration(my_view, :a, 100, 1000, 1001, [], 0, 0)

    spawn(:b, fn -> PBFT.make_replica(base_config) end)
    spawn(:c, fn -> PBFT.make_replica(base_config) end)
    spawn(:d, fn -> PBFT.make_replica(base_config) end)
    spawn(:a, fn -> PBFT.make_primary(base_config) end)





      # key_map=Enum.into(queues, %{})
    client5 =
      spawn(:client, fn ->
        client = PBFT.Client.new_client(:a)
        key_map=PBFT.initialization(base_config, my_view)
        client2= PBFT.Client.set_keys(client, my_view, key_map)
        client3 = PBFT.Client.new_account(client2, "Tom", 1000, whoami())
        client4 = PBFT.Client.update_balance(client3, "Tom", 400, whoami())
        receive do
        after
          5_000 -> true
        end
      end)

    handle = Process.monitor(client5)
    # Timeout.
    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end

#   test "test authentication and validation functions" do
#     Emulation.init()
#     Emulation.append_fuzzers([Fuzzers.delay(2)])

#     base_config =
#       PBFT.new_configuration([:a, :b, :c, :d], :a, 100, 1000, 1001, [], 0, 0)

#     spawn(:b, fn -> PBFT.make_replica(base_config) end)
#     spawn(:c, fn -> PBFT.make_replica(base_config) end)
#     spawn(:d, fn -> PBFT.make_replica(base_config) end)
#     spawn(:a, fn -> PBFT.make_primary(base_config) end)

# PBFT.initialization(base_config, [:a, :b, :c, :d])
#     message = to_string("my messsage")
#     {public, secret} = :crypto.generate_key(:ecdh, :secp256k1)
#     sig = :crypto.sign(:ecdsa, :sha256, message, [secret, :secp256k1])
#     verify_result = :crypto.verify(:ecdsa, :sha256, message, sig, [public, :secp256k1])
#     assert(verify_result)

#     client =
#       spawn(:client, fn ->
#         client = PBFT.Client.new_client(:a)
#         client = PBFT.Client.new_account(client, "Tom", 1000, whoami())
#         client = PBFT.Client.update_balance(client, "Tom", 400, whoami())
#         receive do
#         after
#           5_000 -> true
#         end
#       end)


#     handle = Process.monitor(client)
#     # Timeout.
#     receive do
#       {:DOWN, ^handle, _, _, _} -> true
#     after
#       30_000 -> assert false
#     end
#   after
#     Emulation.terminate()
#   end

end
