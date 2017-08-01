defmodule TrippleStoreTest do
  use ExUnit.Case
  doctest TrippleStore

  test "put, get and delete" do
    context = ["foo"]
    graph = [
      {:a, :b, :d},
      {:a, :b, :c},
      {:d, :e, :f}
    ]

    assert :ok = TrippleStore.put(context, graph)
    assert {:ok, result} = TrippleStore.get(context)
    assert result == graph
    assert :ok = TrippleStore.delete(context)
    assert {:ok, []} = TrippleStore.get(context)
  end

end
