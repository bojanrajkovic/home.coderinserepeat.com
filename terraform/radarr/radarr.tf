resource "kubernetes_namespace" "radarr" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "radarr" {
  depends_on = [kubernetes_namespace.radarr]

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

resource "kubernetes_deployment_v1" "radarr" {
  metadata {
    name      = "radarr"
    namespace = kubernetes_namespace.radarr.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "radarr"
      }
    }

    template {
      metadata {
        name      = "radarr"
        namespace = kubernetes_namespace.radarr.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "radarr"
        }
      }

      spec {
        container {
          name  = "radarr"
          image = "lscr.io/linuxserver/radarr:5.22.4@sha256:01233b9ea9435fd00eab51891f133d86c9b6293f5adb8c3bf44e7a314c9c3423"

          env {
            name  = "PUID"
            value = "1000"
          }

          env {
            name  = "PGID"
            value = "100"
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          port {
            container_port = 7878
            protocol       = "TCP"
          }

          // Configuration
          volume_mount {
            mount_path = "/config"
            name       = var.data_volume_name
          }

          volume_mount {
            mount_path = "/etc/localtime"
            name       = "localtime"
            read_only  = true
          }

          // Data
          dynamic "volume_mount" {
            for_each = var.host_volumes

            content {
              mount_path = "/data/${volume_mount.key}"
              name       = volume_mount.key
            }
          }
        }

        // Configuration
        volume {
          name = var.data_volume_name

          persistent_volume_claim {
            claim_name = var.data_volume_name
          }
        }

        volume {
          name = "localtime"

          host_path {
            type = "File"
            path = "/etc/localtime"
          }
        }

        // Data
        dynamic "volume" {
          for_each = var.host_volumes

          content {
            name = volume.key

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

resource "kubernetes_service_v1" "radarr" {
  metadata {
    name      = "radarr"
    namespace = kubernetes_namespace.radarr.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 7878
      target_port = 7878
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "radarr"
    }
  }
}

resource "kubernetes_ingress_v1" "radarr" {
  metadata {
    name      = "radarr"
    namespace = kubernetes_namespace.radarr.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.radarr_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "radarr"

              port {
                number = 7878
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.radarr_host]
      secret_name = "radarr-ingress-cert"
    }
  }
}
