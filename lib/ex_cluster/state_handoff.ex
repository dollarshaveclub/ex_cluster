defmodule ExCluster.StateHandoff do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # join this crdt with one on another node by adding it as a neighbour
  def join(other_node) do
    # the second element of the tuple, { __MODULE__, node } is a syntax that
    #  identifies the process named __MODULE__ running on the other node other_node
    Logger.warn("Joining StateHandoff at #{inspect other_node}")
    GenServer.call(__MODULE__, { :add_neighbours, { __MODULE__, other_node } })
  end

  # store a customer and order in the handoff crdt
  def handoff(customer, order_contents) do
    GenServer.call(__MODULE__, { :handoff, customer, order_contents })
  end

  # pickup the stored order data for a customer
  def pickup(customer) do
    GenServer.call(__MODULE__, { :pickup, customer })
  end

  def init(_) do
    # custom config for aggressive CRDT sync
    { :ok, crdt_pid } = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
                                             sync_interval: 5,
                                             ship_interval: 5,
                                             ship_debounce: 1)
    { :ok, crdt_pid }
  end

  # other_node is actuall a tuple { __MODULE__, other_node } passed from above,
  #  by using that in GenServer.call we are sending a message to the process
  #  named __MODULE__ on other_node
  def handle_call({ :add_neighbours, other_node }, from, this_crdt_pid) do
    Logger.warn("Sending :add_neighbours to #{inspect other_node} with #{inspect this_crdt_pid}")
    # pass our crdt pid in a message so that the crdt on other_node can add it as a neighbour
    # expect other_node to send back it's crdt_pid in response
    other_crdt_pid = GenServer.call(other_node, { :fulfill_add_neighbours, this_crdt_pid })
    # add other_node's crdt_pid as a neighbour, we need to add both ways so changes in either
    # are reflected across, otherwise it would be one way only
    DeltaCrdt.add_neighbours(this_crdt_pid, [other_crdt_pid])
    { :reply, :ok, this_crdt_pid }
  end

  # the above GenServer.call ends up hitting this callback, but importantly this
  #  callback will run in the other node that was originally being connected to
  def handle_call({ :fulfill_add_neighbours, other_crdt_pid }, _from, this_crdt_pid) do
    Logger.warn("Adding neighbour #{inspect other_crdt_pid} to this #{inspect this_crdt_pid}")
    # add the crdt's as a neighbour, pass back our crdt to the original adding node via a reply
    DeltaCrdt.add_neighbours(this_crdt_pid, [other_crdt_pid])
    { :reply, this_crdt_pid, this_crdt_pid }
  end

  def handle_call({ :handoff, customer, order_contents }, _from, crdt_pid) do
    DeltaCrdt.mutate(crdt_pid, :add, [customer, order_contents])
    Logger.warn("Added #{customer}'s order '#{inspect order_contents} to crdt")
    Logger.warn("CRDT: #{inspect DeltaCrdt.read(crdt_pid)}")
    { :reply, :ok, crdt_pid }
  end

  def handle_call({ :pickup, customer }, _from, crdt_pid) do
    order_contents = crdt_pid
    |> DeltaCrdt.read()
    |> Map.get(customer, [])

    Logger.warn("CRDT: #{inspect DeltaCrdt.read(crdt_pid)}")
    Logger.warn("Picked up #{inspect order_contents, charlists: :as_lists} for #{customer}")
    # remove when picked up, this is a temporary storage and not meant to be used
    #  in any implementation beyond restarting of cross Pod processes
    DeltaCrdt.mutate(crdt_pid, :remove, [customer])

    { :reply, order_contents, crdt_pid }
  end
end