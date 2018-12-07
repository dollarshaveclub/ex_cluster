defmodule ExCluster do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started")

    children = [
      { Registry, keys: :unique, name: ExCluster.Registry },
      { DynamicSupervisor, name: ExCluster.OrderSupervisor, strategy: :one_for_one },
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: ExCluster.Supervisor])
  end
end