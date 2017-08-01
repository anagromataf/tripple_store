defmodule TrippleStoreTest do
  use ExUnit.Case
  doctest TrippleStore

  setup do
    {:ok, agent} = Agent.start_link fn -> [] end
    [ agent: agent ]
  end

  def get(context) do
    Agent.get(context[:agent], fn list -> list end)
  end

  def add(context, value) do
    Agent.update(context[:agent], fn list -> [value|list] end)
  end

  ##
  ## Tests
  ##

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

  describe "select pattern" do

    test "with single match", ctx do
      context = ["foo"]
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        {:a, :b, {:var, "u"}},
        {{:var, "u"}, :e, {:var, "v"}}
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)

      assert [
        %{"u" => :d, "v" => :f}
      ] = bindings
    end

    test "with multiple matches", ctx do
      context = ["foo"]
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f},
        {:d, :e, :g}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        {:a, :b, {:var, "u"}},
        {{:var, "u"}, :e, {:var, "v"}}
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)

      assert [
        %{"u" => :d, "v" => :f},
        %{"u" => :d, "v" => :g}
      ] = Enum.sort(bindings)
    end

    test "without match", ctx do
      context = ["foo"]
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f},
        {:d, :e, :g}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        {:a, :b, {:var, "u"}},
        {{:var, "u"}, :x, {:var, "v"}}
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)
      assert [] = bindings
    end

    test "with different value types", ctx do
      context = ["foo"]
      graph = [
        {:a, :b, "d"},
        {:a, :b, :c},
        {"d", :e, 100}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        {:a, :b, {:var, "u"}},
        {{:var, "u"}, :e, {:var, "v"}}
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)

      assert [
        %{"u" => "d", "v" => 100}
      ] = bindings
    end

  end

end
