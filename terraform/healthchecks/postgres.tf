resource "kubernetes_manifest" "healthchecks_cluster" {
  depends_on = [kubernetes_namespace.healthchecks_io]

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "healthchecks-cluster"
      namespace = kubernetes_namespace.healthchecks_io.metadata[0].name
    }

    spec = {
      instances = 1

      storage = {
        size         = "50Gi"
        storageClass = "zfs-durable"
      }

      bootstrap = {
        initdb = {
          database = "hc"
          owner    = "hc"
        }
      }

      managed = {
        services = {
          additional = [
            {
              selectorType = "rw"
              serviceTemplate = {
                metadata = {
                  name      = "healthchecks-cluster"
                  namespace = kubernetes_namespace.healthchecks_io.metadata[0].name

                  annotations = {
                    "external-dns.alpha.kubernetes.io/hostname"  = var.postgres_hostname
                    "metallb.universe.tf/ip-allocated-from-pool" = "metallb-address-pool"
                  }
                }

                spec = {
                  type = "LoadBalancer"
                }
              }
            }
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "healthchecks_cluster_monitor" {
  depends_on = [kubernetes_manifest.healthchecks_cluster]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = "healthchecks-cluster-monitor"
      namespace = kubernetes_namespace.healthchecks_io.metadata[0].name

      labels = {
        "release" = "kube-prometheus"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          "cnpg.io/cluster" = kubernetes_manifest.healthchecks_cluster.manifest.metadata.name
        }
      }

      podMetricsEndpoints = [{ port = "metrics" }]
    }
  }
}
