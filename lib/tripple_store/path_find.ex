defmodule TrippleStore.PathFind do

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

  def do_find_path(_context, from, to, fun, _visited, path) when from == to, do: fun.(Enum.reverse(path))
  def do_find_path(context, from, to, fun, visited, path) do
    for {_, _, _, attr, next} <- get_neighbours(context, from) do
      unless Enum.member?(visited, next) do
        do_find_path(context, next, to, fun, [from|visited], [{from, attr, next}|path])
      end
    end
    :ok
  end

  def get_neighbours(context, node) do
     match_pattern = {:statement, context, node, :'_', :'_'}
     :mnesia.match_object(:tripple_store, match_pattern, :read)
  end

end
