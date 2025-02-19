locals {
  host_volumes = toset(["/run/udev"])
  resources = tomap({ for capacity
    in[
      for key in [
        for key in keys(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity) :
        key
        if length(regexall("^.*sd[a-z]$", key)) > 0
      ] :
      key
      if tonumber(data.kubernetes_nodes.hagal.nodes[0].status[0].capacity[key]) > 0
    ] :
    capacity => 1
  })
}

resource "kubernetes_namespace" "scrutiny" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

data "kubernetes_nodes" "hagal" {
  metadata {
    labels = {
      "kubernetes.io/hostname" = "hagal"
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "scrutiny_config" {
  depends_on = [kubernetes_namespace.scrutiny]

  metadata {
    name      = var.config_volume_name
    namespace = var.namespace_name
  }

  spec {
    storage_class_name = var.config_volume_storage_class
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.config_volume_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "scrutiny_influxdb" {
  depends_on = [kubernetes_namespace.scrutiny]

  metadata {
    name      = var.influxdb_volume_name
    namespace = var.namespace_name
  }

  spec {
    storage_class_name = var.influxdb_volume_storage_class
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.influxdb_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "scrutiny" {
  depends_on = [
    kubernetes_namespace.scrutiny,
    data.kubernetes_nodes.hagal,
    kubernetes_persistent_volume_claim_v1.scrutiny_config,
    kubernetes_persistent_volume_claim_v1.scrutiny_influxdb
  ]

  metadata {
    name      = "scrutiny"
    namespace = kubernetes_namespace.scrutiny.metadata[0].name
  }


  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "scrutiny"
      }
    }

    template {
      metadata {
        name      = "scrutiny"
        namespace = kubernetes_namespace.scrutiny.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "scrutiny"
        }
      }

      spec {
        os {
          name = "linux"
        }

        node_name = "hagal"

        container {
          image = "ghcr.io/analogj/scrutiny:v0.8.1-omnibus@sha256:66a65d1d7f2bf330a55e0bb073a3b2496a7b61dc6414c8c53550bc0c3f6885dd"
          name  = "scrutiny"

          port {
            name           = "web"
            container_port = 8080
            protocol       = "TCP"
          }

          dynamic "volume_mount" {
            for_each = tomap({
              "config"   = var.config_volume_name,
              "influxdb" = var.influxdb_volume_name
            })

            content {
              mount_path = "/opt/scrutiny/${volume_mount.key}"
              name       = volume_mount.value
            }
          }

          dynamic "volume_mount" {
            for_each = local.host_volumes

            content {
              mount_path = volume_mount.value
              name       = basename(volume_mount.value)
            }
          }

          resources {
            requests = local.resources
            limits   = local.resources
          }

          security_context {
            capabilities {
              add = ["SYS_RAWIO"]
            }
          }
        }

        dynamic "volume" {
          for_each = toset([
            var.config_volume_name,
            var.influxdb_volume_name
          ])

          content {
            name = volume.value

            persistent_volume_claim {
              claim_name = volume.value
            }
          }
        }

        // Backup volumes
        dynamic "volume" {
          for_each = local.host_volumes

          content {
            name = basename(volume.value)

            host_path {
              type = "Directory"
              path = volume.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "scrutiny" {
  metadata {
    name      = "scrutiny"
    namespace = kubernetes_namespace.scrutiny.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      name        = "web"
      port        = 80
      protocol    = "TCP"
      target_port = "web"
    }

    selector = {
      "app.kubernetes.io/name" = "scrutiny"
    }
  }
}

resource "kubernetes_ingress_v1" "scrutiny" {
  depends_on = [kubernetes_namespace.scrutiny, kubernetes_service_v1.scrutiny]

  metadata {
    name      = "scrutiny"
    namespace = kubernetes_namespace.scrutiny.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.scrutiny_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "scrutiny"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.scrutiny_host]
      secret_name = "scrutiny-ingress-cert"
    }
  }
}
