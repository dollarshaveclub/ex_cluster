# ExCluster

ExCluster is a demo application built with Elixir and OTP to show how to integrate
Distributed Elixir on Kubernetes with Horde, LibCluster, and Distillery. The application
mimics a service in charge of processing orders, a GenServer models a order and
stores in it's state a list of integers as order contents. All state is kept in-memory,
and using Distributed Elixir and Horde when a Node goes down gracefully, processes
are restarted throughout the remaining Cluster Nodes (with process state transferred).
This is integrated on Kubernetes via a HeadlessService setup with LibCluster.

## Running Locally - Single Node

You can run the application locally simply via `iex -S mix`, this will run a single Node
without any clustering.

## Running Locally - MultiNode

To run a Cluster locally, run the application multiple times with unique Node names and a
consistent cookie specified via `ERL_FLAGS`, for example this will run a 3 Node cluster:

```
# Terminal 1
$ ERL_FLAGS="-name count1@127.0.0.1 -setcookie cookie" NODES="count2@127.0.0.1,count3@127.0.0.1" iex -S mix

# Terminal 2
$ ERL_FLAGS="-name count2@127.0.0.1 -setcookie cookie" NODES="count1@127.0.0.1,count3@127.0.0.1" iex -S mix

# Terminal 3
$ ERL_FLAGS="-name count3@127.0.0.1 -setcookie cookie" NODES="count1@127.0.0.1,count2@127.0.0.1" iex -S mix
```

## Running on `minikube`

To run on `minikube`, start it up and then deploy the charts:

```
$ kubectl create -f k8s/service-headless.yaml
$ kubectl create -f k8s/deployment.yaml
```

You can now get Pods, exec onto one and create orders, kill the Pod, and view the restarted
order process with state still alive in the Cluster.
