defmodule LibCluster.LocalStrategy do
  # this defines a strategy used in our local dev environment
  # assuming a list of Nodes is defined in the runtime environment,
  #  we use that to connect our cluster
  use Cluster.Strategy
  alias Cluster.Strategy.State

  def start_link([%State{} = state]) do
    case System.get_env("NODES") do
      node_binary_list when is_binary(node_binary_list) ->
        nodes = convert_to_nodes(node_binary_list)
        Cluster.Strategy.connect_nodes(state.topology, state.connect, state.list_nodes, nodes)
        :ignore
      _ ->
        :ignore
    end
  end

  def convert_to_nodes(node_binary_list) do
    node_binary_list
    |> String.split(",")
    |> Enum.map(&String.to_atom/1)
  end
end