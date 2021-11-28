IO.puts("this is a project test")
defmodule ProjectTest do
  use ExUnit.Case
  doctest PBFT

  defp print_a do
    # PBFT.new_configuration()
    IO.puts("this is a project test function")
    PBFT.test_function()
  end



  test "simple project test" do
    print_a()
    IO.puts("this is a simple test")
  end
end
