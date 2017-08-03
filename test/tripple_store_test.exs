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

  describe "manage context" do
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

    test "add to context" do
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f}
      ]
      context = ["foo"]
      assert :ok = TrippleStore.put(context, graph)
      assert :ok = TrippleStore.add(context, [{:x, :y, :z}])
      assert {:ok, result} = TrippleStore.get(context)
      assert [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f},
        {:x, :y, :z}
      ] = result
    end

    test "add same to context" do
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f}
      ]
      context = ["foo"]
      assert :ok = TrippleStore.put(context, graph)
      assert :ok = TrippleStore.add(context, [{:d, :e, :f}])
      assert {:ok, result} = TrippleStore.get(context)
      assert [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f}
      ] = result
    end
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

  describe "filter selected" do
    test "with a function, val and, value", ctx do
      context = ["foo"]
      graph = [
        {:x, :a, 100},
        {:x, :c, 200},
        {:x, :d, 300},
        {:x, :e, 400},
        {:x, :f, 500}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        match(value(:x), var("attr"), var("n")),
        filter(&>/2, var("n"), value(300))
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)

      assert [
        %{"attr" => :e, "n" => 400},
        %{"attr" => :f, "n" => 500}
      ] = Enum.sort(bindings)
    end

    test "unbound var", ctx do
      context = ["foo"]
      graph = [
        {:x, :a, 100},
        {:x, :c, 200},
        {:x, :d, 300},
        {:x, :e, 400},
        {:x, :f, 500}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        match(value(:x), var("attr"), var("n")),
        filter(&>/2, var("x"), value(300))
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)
      assert [] = bindings
    end

    test "with two vars", ctx do
      context = ["foo"]
      graph = [
        {:x, :a, 100},
        {:x, :b, 200},
        {:y, :a, 500},
        {:y, :b, 400},
        {:y, :b, 600}
      ]
      assert :ok = TrippleStore.put(context, graph)

      pattern = [
        match(var("n"), value(:a), var("a")),
        match(var("n"), value(:b), var("b")),
        filter(&>/2, var("a"), var("b"))
      ]

      fun = fn(binding) ->
        add(ctx, binding)
      end

      assert :ok = TrippleStore.select(context, pattern, fun)

      bindings = get(ctx)

      assert [
        %{"a" => 500, "b" => 400, "n" => :y}
      ] = bindings
    end
  end

  test "find path", ctx do
    context = ["foo"]
    graph = [
      {:a, :x, :b},
      {:b, :x, :c},
      {:c, :x, :d},
      {:b, :x, :d},
      {:u, :x, :d},
      {:b, :x, :u},
      {:a, :x, :u},
    ]
    assert :ok = TrippleStore.put(context, graph)
    assert :ok = TrippleStore.path(context, :a, :d, &add(ctx, &1))
    assert [
      [{:a, :x, :b}, {:b, :x, :c}, {:c, :x, :d}],
      [{:a, :x, :b}, {:b, :x, :d}],
      [{:a, :x, :b}, {:b, :x, :u}, {:u, :x, :d}],
      [{:a, :x, :u}, {:u, :x, :d}]
    ] = Enum.sort(get(ctx))
  end

end
