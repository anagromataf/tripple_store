defmodule TrippleStore.PathFind.DepthFirstSearch do

  def path(context, from, to, fun) do
    transaction = fn () -> do_find_path(context, from, to, fun, [], []) end
    with {:atomic, result} <- :mnesia.transaction(transaction) do
      result
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  ##
  ## Private
  ##

  import TrippleStore.Access

  defp do_find_path(_context, from, to, fun, _visited, path) when from == to, do: fun.(Enum.reverse(path))
  defp do_find_path(context, from, to, fun, visited, path) do
    get_values(context, from, fn(attr, next) ->
      unless Enum.member?(visited, next) do
        do_find_path(context, next, to, fun, [from|visited], [{from, attr, next}|path])
      end
    end)
    :ok
  end

end
