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

  @type var :: {:var, label :: term}
  @type binding :: %{var => any}
  @type pattern :: [{subject | var, predicate | var, object | var}]

  @type error :: {:error, reason :: any}

  @spec put(context, graph) :: :ok | error
  def put(context, graph), do: TrippleStore.Access.put(context, graph)

  @spec get(context) :: {:ok, graph} | error
  def get(context), do: TrippleStore.Access.get(context)

  @spec delete(context) :: :ok | error
  def delete(context), do: TrippleStore.Access.delete(context)

  @spec select(context, pattern, (binding -> any)) :: :ok | error
  def select(context, pattern, fun), do: TrippleStore.Access.select(context, pattern, fun)

end
