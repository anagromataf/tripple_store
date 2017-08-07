defmodule TrippleStore.Setup do

  def run(args) do
    with :ok <- create_table(args),
         :ok <- wait_for_table(args) do
      :ok
    end
  end

  ##
  ## Private
  ##

  defp create_table(args) do
    with {:atomic, :ok} <- :mnesia.create_table(:tripple_store, table_definition(args)),
         {:atomic, :ok} <- :mnesia.add_table_index(:tripple_store, :subject),
         {:atomic, :ok} <- :mnesia.add_table_index(:tripple_store, :predicate),
         {:atomic, :ok} <- :mnesia.add_table_index(:tripple_store, :object) do
      :ok
    else
      {:aborted, {:already_exists, :tripple_store}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp table_definition(args) do
    nodes = [node()]
    poperties = [
      type: :bag,
      attributes: [:context, :subject, :predicate, :object],
      record_name: :statement,
    ]
    if Keyword.get(args, :persistent, false) do
      [{:disc_copies, nodes} | poperties]
    else
      [{:ram_copies, nodes} | poperties]
    end
  end

  defp wait_for_table(_args) do
    :mnesia.wait_for_tables([:tripple_store], :infinity)
  end

end
