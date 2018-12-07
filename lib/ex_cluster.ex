defmodule ExCluster do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started")

    case System.get_env("NODES") do
      nodes when is_binary(nodes) ->
        nodes
        # convert list of nodes into atoms of node names
        |> String.split(",")
        |> Enum.map(&String.to_atom/1)
        # connect to all nodes to make a cluster
        |> Enum.each(&Node.connect/1)
      _ ->
        nil
    end

    children = [
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
              end)
            end
          ]
        }
      }
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: ExCluster.Supervisor])
  end
end