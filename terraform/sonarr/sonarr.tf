resource "kubernetes_namespace" "sonarr" {
  metadata {
    name = var.namespace_name
    labels = {
      "operator.1password.io/auto-restart" : true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "sonarr" {
  depends_on = [kubernetes_namespace.sonarr]
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

resource "kubernetes_deployment_v1" "sonarr" {
  depends_on = [kubernetes_namespace.sonarr, kubernetes_persistent_volume_claim_v1.sonarr]

  metadata {
    name      = "sonarr"
    namespace = kubernetes_namespace.sonarr.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "sonarr"
      }
    }

    template {
      metadata {
        name      = "sonarr"
        namespace = kubernetes_namespace.sonarr.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "sonarr"
        }
      }

      spec {
        container {
          name  = "sonarr"
          image = "lscr.io/linuxserver/sonarr:4.0.6@sha256:3f193d343c1225676c1ea0547c5022fd83c4459a493870179dff9e87c54dbbc9"

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
            container_port = 8989
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

resource "kubernetes_service_v1" "sonarr" {
  metadata {
    name      = "sonarr"
    namespace = kubernetes_namespace.sonarr.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 8989
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" : "sonarr"
    }
  }
}

resource "kubernetes_ingress_v1" "sonarr" {
  metadata {
    name      = "sonarr"
    namespace = kubernetes_namespace.sonarr.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = var.sonarr_host
      http {
        path {
          path = "/"
          backend {
            service {
              name = "sonarr"
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
      hosts       = [var.sonarr_host]
      secret_name = "sonarr-ingress-cert"
    }
  }
}
