resource "kubernetes_namespace_v1" "home_assistant" {
  count = 0
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "recorder_cluster" {
  count = 0

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "recorder-cluster"
      namespace = kubernetes_namespace_v1.home_assistant[0].metadata[0].name
    }

    spec = {
      instances = 1

      storage = {
        size         = "50Gi"
        storageClass = "zfs-durable"
      }

      bootstrap = {
        initdb = {
          database = "recorder"
          owner    = "homeassistant"
        }
      }

      managed = {
        services = {
          additional = [
            {
              selectorType = "rw"
              serviceTemplate = {
                metadata = {
                  name      = "ha-recorder"
                  namespace = kubernetes_namespace_v1.home_assistant[0].metadata[0].name

                  annotations = {
                    "external-dns.alpha.kubernetes.io/hostname" = var.postgres_hostname
                    "metallb.io/ip-allocated-from-pool"         = "metallb-address-pool"
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

resource "kubernetes_manifest" "recorder_cluster_monitor" {
  count      = 0
  depends_on = [kubernetes_manifest.recorder_cluster]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = "recorder-cluster-monitor"
      namespace = kubernetes_namespace_v1.home_assistant[0].metadata[0].name

      labels = {
        "release" = "kube-prometheus"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          "cnpg.io/cluster" = kubernetes_manifest.recorder_cluster[0].manifest.metadata.name
        }
      }

      podMetricsEndpoints = [{ port = "metrics" }]
    }
  }
}
