defmodule TrippleStoreSpec do
  use ESpec

  context "Adding a graph to the store" do

    before do
      context = ["foo"]
      graph = [
        {:a, :b, :d},
        {:a, :b, :c},
        {:d, :e, :f}
      ]
      :ok = TrippleStore.put(context, graph)
      {:shared, %{context: context, graph: graph}}
    end

    it "should contain the graph" do
      {:ok, result} = TrippleStore.get(shared.context)
      shared.graph |> should(eq result)
    end

  end

end
