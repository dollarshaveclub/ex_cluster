defmodule ExCluster do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started: DSC v2")

    # topologies = Application.get_env(:libcluster, :topologies)

    Logger.info("Pulling node addresses from DNS")
    { :ok, { _, _, _, _, _, addresses } } = :inet_res.getbyname(:"ex-cluster.default.svc.cluster.local", :a)
    Logger.info("Got the following node ips: #{inspect addresses}")
    addresses
    |> Enum.map(&:inet_parse.ntoa(&1))
    |> Enum.map(&"ex_cluster@#{&1}")
    |> Enum.map(&String.to_atom(&1))
    |> Enum.map(&Node.connect(&1))
    Logger.info("Connected to all the Nodes")
    children = [
      # { Cluster.Supervisor, [topologies, [name: ExCluster.ClusterSupervisor]] },
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