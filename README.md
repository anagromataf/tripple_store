# TrippleStore

TrippleStore is a simple store, that uses mnesia to persist graphs based on triples (subject, predicate, object).

Any value an be used int the tripples:

```
graph = [
  {:a, :b, "d"},
  {:a, :b, :c},
  {"d", :e, 100}
]

context = ["foo"]

TrippleStore.put(context, graph)
```

The graph can be accessed by the context:

```
TrippleStore.get(context)
```

It is also possible to select values matching a pattern in a context.

```
import TrippleStore.Pattern

pattern = [
  match(value(:a), value(:b), var("u")),
  match(var("u"), value(:e), var("v"))
]

fun = fn(binding) ->
  IO.inspect binding
end

TrippleStore.select(context, pattern, fun)
```

The function `fun` is called for each match of the pattern with the values matching the pattern bound to the variables.

```
%{"u" => "d", "v" => 100}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tripple_store` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tripple_store, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tripple_store](https://hexdocs.pm/tripple_store).
