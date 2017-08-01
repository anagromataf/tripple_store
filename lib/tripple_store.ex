defmodule TrippleStore do
  @moduledoc """
  Documentation for TrippleStore.
  """

  @type context :: [term]

  @type subject :: term
  @type predicate :: term
  @type object :: term
  @type tripple :: {subject, predicate, object}
  @type graph :: [tripple]

  @type binding :: %{name :: any => value :: any}
  @type error :: {:error, reason :: any}

  @spec put(context, graph) :: :ok | error
  def put(context, graph), do: TrippleStore.Access.put(context, graph)

  @spec add(context, graph) :: :ok | error
  def add(context, graph), do: TrippleStore.Access.add(context, graph)

  @spec get(context) :: {:ok, graph} | error
  def get(context), do: TrippleStore.Access.get(context)

  @spec delete(context) :: :ok | error
  def delete(context), do: TrippleStore.Access.delete(context)

  @spec select(context, Pattern.t, (binding -> any)) :: :ok | error
  def select(context, pattern, fun), do: TrippleStore.Access.select(context, pattern, fun)

  defmodule Pattern do
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
  end

end
