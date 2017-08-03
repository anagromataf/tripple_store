defmodule TrippleStore.Access do

  import TrippleStore.Pattern

  @spec put(TrippleStore.context, TrippleStore.graph) :: :ok | TrippleStore.error
  def put(context, graph) do
    transaction = fn () -> do_put(context, graph) end
    with {:atomic, :ok} <- :mnesia.transaction(transaction) do
      :ok
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec add(TrippleStore.context, TrippleStore.graph) :: :ok | TrippleStore.error
  def add(context, graph) do
    transaction = fn () -> do_add(context, graph) end
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

  @type values_fun :: ((TrippleStore.predicate, TrippleStore.object) -> any)
  @spec get_values(TrippleStore.context, TrippleStore.subject, values_fun) :: :ok | TrippleStore.error
  def get_values(context, subject, fun) do
    pattern = [match(value(subject), var(:predicate), var(:object))]
    f = fn(binding) ->
      predicate = binding[:predicate]
      object = binding[:object]
      fun.(predicate, object)
    end
    with {:error, reason} <- select(context, pattern, f) do
       :mnesia.abort(reason)
    end
  end

  @spec select(TrippleStore.context, TrippleStore.pattern, (TrippleStore.binding -> any)) :: :ok | TrippleStore.error
  def select(context, pattern, fun) do
    query = Enum.group_by(pattern, &elem(&1, 0))
    match = Map.get(query, :match, [])
    filter = Map.get(query, :filter, [])
    transaction = fn () -> do_select(context, match, filter, fun, %{}) end
    with {:atomic, result} <- :mnesia.transaction(transaction) do
      result
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

  defp do_add(context, graph) do
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

  defp do_select(_context, [], [], fun, binding), do: fun.(binding)
  defp do_select(context, [], [filter|filters], fun, binding) do
    if apply_filter(filter, binding) do
      do_select(context, [], filters, fun, binding)
    end
  end
  defp do_select(context, [tripple|pattern], filter, fun, binding) do
    for match <- match_triple(context, tripple, binding) do
      new_binding = update_binding(match, tripple, binding)
      do_select(context, pattern, filter, fun, new_binding)
    end
    :ok
  end

  defp match_triple(context, {:match, subject, predicate, object}, binding) do
    new_subject = bind_var(subject, binding)
    new_predicate = bind_var(predicate, binding)
    new_object = bind_var(object, binding)
    match_pattern = {:statement, context, new_subject, new_predicate, new_object}
    :mnesia.match_object(:tripple_store, match_pattern, :read)
  end

  defp bind_var({:var, name}, binding), do: Map.get(binding, name, :'_')
  defp bind_var({:value, value}, _binding), do: value

  defp update_binding({_, _, m_s, m_p, m_o}, {_, p_s, p_p, p_o}, binding) do
    binding
    |> bind_match(p_s, m_s)
    |> bind_match(p_p, m_p)
    |> bind_match(p_o, m_o)
  end

  defp bind_match(binding, {:var, name}, value) do
    Map.put(binding, name, value)
  end
  defp bind_match(binding, _, _), do: binding

  defp apply_filter({:filter, fun, lhs, rhs}, binding) do
    with lhs when lhs != :'_' <- bind_var(lhs, binding),
         rhs when rhs != :'_' <- bind_var(rhs, binding) do
        fun.(lhs, rhs)
    else
      _ -> false
    end
  end

end
