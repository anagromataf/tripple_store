defmodule TrippleStore.Pattern do
  @type var :: {:var, label :: any}
  @type value :: {:value, any}
  @type match :: {
    :match,
    subject :: var | value,
    predicate :: var | value,
    object :: var | value
  }
  @type t :: [match]

  def var(name), do: {:var, name}

  def value(val), do: {:value, val}

  def match(subject, predicate, object) do
    {:match, subject, predicate, object}
  end

  def filter(fun, lhs, rhs) do
    {:filter, fun, lhs, rhs}
  end
end
