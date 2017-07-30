defmodule TrippleStore.Application do
  use Application

  def start(_type, args) do
    with :ok <- TrippleStore.Setup.run(args) do
      children = []
      opts = [strategy: :one_for_one, name: TrippleStore.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
end
