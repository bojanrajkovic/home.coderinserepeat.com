resource "kubernetes_namespace" "lidarr" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "lidarr" {
  depends_on = [kubernetes_namespace.lidarr]

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

resource "kubernetes_deployment_v1" "lidarr" {
  depends_on = [kubernetes_namespace.lidarr, kubernetes_persistent_volume_claim_v1.lidarr]

  metadata {
    name      = "lidarr"
    namespace = kubernetes_namespace.lidarr.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "lidarr"
      }
    }

    template {
      metadata {
        name      = "lidarr"
        namespace = kubernetes_namespace.lidarr.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "lidarr"
        }
      }

      spec {
        container {
          name  = "lidarr"
          image = "lscr.io/linuxserver/lidarr:latest@sha256:2452f5df3b6e3a267c419382a1e492c6831a5e46a01c3aec11c61a7810e15d6f"

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
            container_port = 8686
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

          // Music
          volume_mount {
            mount_path = "/music"
            name       = "music"
          }

          // Downloads
          volume_mount {
            mount_path = "/downloads"
            name       = "downloads"
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

        // Music
        volume {
          name = "music"

          host_path {
            type = "Directory"
            path = var.music_host_path
          }
        }

        // Downloads
        volume {
          name = "downloads"

          host_path {
            type = "Directory"
            path = var.downloads_host_path
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "lidarr" {
  metadata {
    name      = "lidarr"
    namespace = kubernetes_namespace.lidarr.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 8686
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "lidarr"
    }
  }
}

resource "kubernetes_ingress_v1" "lidarr" {
  metadata {
    name      = "lidarr"
    namespace = kubernetes_namespace.lidarr.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.lidarr_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "lidarr"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.lidarr_host]
      secret_name = "lidarr-ingress-cert"
    }
  }
}
