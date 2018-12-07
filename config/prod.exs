use Mix.Config

config :libcluster,
  topologies: [
    k8s_example: [
      strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
      config: [
        service: "excluster-service-headless",
        application_name: "ex_cluster",
        polling_interval: 3_000
      ]
    ]
  ]