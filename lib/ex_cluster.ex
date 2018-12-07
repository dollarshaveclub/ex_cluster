defmodule ExCluster do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started: DSC")

    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      { Cluster.Supervisor, [topologies, [name: ExCluster.ClusterSupervisor]] },
      { ExCluster.StateHandoff, [] },
      { Horde.Registry, [name: ExCluster.Registry, keys: :unique] },
      { Horde.Supervisor, [name: ExCluster.OrderSupervisor, strategy: :one_for_one ] },
      %{
        id: ExCluster.HordeConnector,
        restart: :transient,
        start: {
          Task, :start_link, [
            fn ->
              Node.list()
              |> Enum.each(fn node ->
                Horde.Cluster.join_hordes(ExCluster.OrderSupervisor, { ExCluster.OrderSupervisor, node })
                Horde.Cluster.join_hordes(ExCluster.Registry, { ExCluster.Registry, node })
                :ok = ExCluster.StateHandoff.join(node)
              end)
            end
          ]
        }
      }
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: ExCluster.Supervisor])
  end
end