resource "kubernetes_namespace_v1" "outline" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "outline_cluster" {
  depends_on = [kubernetes_namespace_v1.outline]

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "outline-cluster"
      namespace = kubernetes_namespace_v1.outline.metadata[0].name
    }

    spec = {
      instances = 1

      storage = {
        size         = "50Gi"
        storageClass = "zfs-durable"
      }

      bootstrap = {
        initdb = {
          database = "outline"
          owner    = "outline"
        }
      }

      managed = {
        services = {
          additional = [
            {
              selectorType = "rw"
              serviceTemplate = {
                metadata = {
                  name      = "outline-cluster"
                  namespace = kubernetes_namespace_v1.outline.metadata[0].name

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

resource "kubernetes_manifest" "outline_cluster_monitor" {
  depends_on = [kubernetes_manifest.outline_cluster]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = "outline-cluster-monitor"
      namespace = kubernetes_namespace_v1.outline.metadata[0].name

      labels = {
        "release" = "kube-prometheus"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          "cnpg.io/cluster" = kubernetes_manifest.outline_cluster.manifest.metadata.name
        }
      }

      podMetricsEndpoints = [{ port = "metrics" }]
    }
  }
}
