defmodule TrippleStoreTest do
  use ExUnit.Case
  import TrippleStore.Pattern

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
        match(value(:a), value(:b), var("u")),
        match(var("u"), value(:e), var("v"))
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
        match(value(:a), value(:b), var("u")),
        match(var("u"), value(:e), var("v"))
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
        match(value(:a), value(:b), var("u")),
        match(var("u"), value(:xxx), var("v"))
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
        match(value(:a), value(:b), var("u")),
        match(var("u"), value(:e), var("v"))
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

    test "with var as value", ctx do

      # Allow the use of the tuple used for valiables in
      # patterns to ab a value in the graph.
      # If the graph contains the value `{:var, "a label"}`, it
      # should not be treated as a variable in the match.
      
      context = ["foo"]
      graph = [
        {:a, :b, "d"},
        {:a, :b, {:var, "u"}},
        {"d", :e, 100}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        match(value(:a), value(:b), var("u")),
        match(var("u"), value(:e), var("v"))
      ]

      assert :ok = TrippleStore.select(context, pattern, &add(ctx, &1))
      assert [%{"u" => "d", "v" => 100}] = get(ctx)
    end

    test "with specific contexts", ctx do
      assert :ok = TrippleStore.put(["foo", "1"], [{:a, :b, :c}])
      assert :ok = TrippleStore.put(["foo", "2"], [{:a, :b, :d}])

      pattern = [match(value(:a), value(:b), var("u"))]

      assert :ok = TrippleStore.select(["foo", "1"], pattern, &add(ctx, &1))
      assert [%{"u" => :c}] = get(ctx)
    end

  end

end
