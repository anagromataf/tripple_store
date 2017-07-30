defmodule TrippleStore.Setup do

  def run(_args) do
    with :ok <- create_table(),
         :ok <- wait_for_table() do
      :ok
    end
  end

  ##
  ## Private
  ##

  defp create_table do
    with {:atomic, :ok} <- :mnesia.create_table(:tripple_store, table_definition()) do
      :ok
    else
      {:aborted, {:already_exists, :tripple_store}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp wait_for_table do
    :mnesia.wait_for_tables([:tripple_store], :infinity)
  end

  defp table_definition do
    [type: :bag,
     attributes: [:context, :subject, :predicate, :object],
     record_name: :statement,
     ram_copies: [node()]]
  end

end
