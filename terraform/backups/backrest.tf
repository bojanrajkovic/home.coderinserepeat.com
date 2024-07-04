resource "kubernetes_namespace" "backrest" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "backrest_data" {
  depends_on = [kubernetes_namespace.backrest]
  metadata {
    name      = var.data_volume_name
    namespace = var.namespace_name
  }
  spec {
    storage_class_name = var.data_volume_storage_class
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.data_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "backrest" {
  depends_on = [kubernetes_namespace.backrest]

  metadata {
    name      = "backrest"
    namespace = kubernetes_namespace.backrest.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "backrest"
      }
    }
    template {
      metadata {
        name      = "backrest"
        namespace = kubernetes_namespace.backrest.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "backrest"
        }
      }
      spec {
        os {
          name = "linux"
        }

        node_name = "hagal"

        container {
          image = "docker.io/garethgeorge/backrest:v1.2.1@sha256:591013954d99cdb5a064c2941153ec0077a6dfcd640f8f19dd47d43e99812a61"
          name  = "backrest"

          port {
            name           = "web"
            container_port = 9898
            protocol       = "TCP"
          }

          dynamic "env" {
            for_each = tomap({
              BACKREST_DATA   = "/data",               # path for backrest data. restic binary and the database are placed here.
              BACKREST_CONFIG = "/config/config.json", # path for the backrest config file.
              XDG_CACHE_HOME  = "/cache"               # path for the restic cache which greatly improves performance.
            })

            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "volume_mount" {
            for_each = var.configuration_volumes

            content {
              mount_path = "/${volume_mount.value}"
              name       = "backrest-data"
              sub_path   = volume_mount.value
            }
          }

          dynamic "volume_mount" {
            for_each = var.backup_volumes

            content {
              mount_path        = "/userdata/${basename(volume_mount.value)}"
              name              = basename(volume_mount.value)
              mount_propagation = "HostToContainer"
            }
          }
        }

        volume {
          name = "backrest-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.backrest_data.metadata[0].name
          }
        }

        dynamic "volume" {
          for_each = var.backup_volumes

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

resource "kubernetes_service_v1" "backrest" {
  metadata {
    name      = "backrest-srv"
    namespace = kubernetes_namespace.backrest.metadata[0].name
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
      "app.kubernetes.io/name" : "backrest"
    }
  }
}

resource "kubernetes_ingress_v1" "backrest" {
  depends_on = [kubernetes_namespace.backrest, kubernetes_service_v1.backrest]

  metadata {
    name      = "backrest"
    namespace = kubernetes_namespace.backrest.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = var.backrest_hostname
      http {
        path {
          path = "/"
          backend {
            service {
              name = "backrest-srv"
              port {
                number = 80
              }
            }
          }
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts       = [var.backrest_hostname]
      secret_name = "backrest-ingress-cert"
    }
  }
}
