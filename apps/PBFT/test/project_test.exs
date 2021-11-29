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

    base_config =
      PBFT.new_configuration([:a, :b, :c, :d], :a, 100, 1000, 1001, [], 0, 0)

    spawn(:b, fn -> PBFT.make_replica(base_config) end)
    spawn(:c, fn -> PBFT.make_replica(base_config) end)
    spawn(:d, fn -> PBFT.make_replica(base_config) end)
    spawn(:a, fn -> PBFT.make_primary(base_config) end)

    client =
      spawn(:client, fn ->
        client = PBFT.Client.new_client(:a)
        PBFT.Client.new_account(client, "Tom", 1000, whoami())
        receive do
        after
          5_000 -> true
        end
      end)

    handle = Process.monitor(client)
    # Timeout.
    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end
end
