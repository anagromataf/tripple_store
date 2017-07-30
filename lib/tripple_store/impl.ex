defmodule TrippleStore.Impl do

  @spec put(TrippleStore.context, TrippleStore.graph) :: :ok | TrippleStore.error
  def put(context, graph) do
    transaction = fn () -> do_put(context, graph) end
    with {:atomic, :ok} <- :mnesia.transaction(transaction) do
      :ok
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec get(TrippleStore.context) :: {:ok, TrippleStore.graph} | TrippleStore.error
  def get(context) do
    transaction = fn () -> do_get(context) end
    with {:atomic, result} <- :mnesia.transaction(transaction) do
      {:ok, result}
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec delete(TrippleStore.context) :: :ok | TrippleStore.error
  def delete(context) do
    transaction = fn () -> do_delete(context) end
    with {:atomic, :ok} <- :mnesia.transaction(transaction) do
      :ok
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  ##
  ## Private
  ##

  defp do_put(context, graph) do
    :ok = do_delete(context)
    :ok = do_insert(context, graph)
  end

  defp do_insert(_context, []), do: :ok
  defp do_insert(context, [{s, p, o}|graph]) do
    :ok = :mnesia.write(:tripple_store, {:statement, context, s, p, o}, :write)
    do_insert(context, graph)
  end

  defp do_get(context) do
    :mnesia.read(:tripple_store, context)
    |> Enum.map(fn({_, _, s, p, o}) -> {s, p, o} end)
  end

  defp do_delete(context) do
    :ok = :mnesia.delete(:tripple_store, context, :write)
  end

end
