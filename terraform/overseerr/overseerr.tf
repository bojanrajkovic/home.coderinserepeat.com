resource "kubernetes_namespace" "overseerr" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "overseerr" {
  depends_on = [kubernetes_namespace.overseerr]

  metadata {
    name      = var.data_volume_name
    namespace = var.namespace_name
  }

  spec {
    storage_class_name = var.data_volume_storage_class
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.data_volume_size
      }
    }
  }
}

resource "kubernetes_deployment_v1" "overseerr" {
  depends_on = [kubernetes_namespace.overseerr, kubernetes_persistent_volume_claim_v1.overseerr]

  metadata {
    name      = "overseerr"
    namespace = kubernetes_namespace.overseerr.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "overseerr"
      }
    }

    template {
      metadata {
        name      = "overseerr"
        namespace = kubernetes_namespace.overseerr.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "overseerr"
        }
      }

      spec {
        container {
          name  = "overseerr"
          image = "sctx/overseerr:latest@sha256:4f38f58d68555004d3f487a4c5cbe2823e6a0942d946a25a2d9391d8492240a4"

          env {
            name  = "LOG_LEVEL"
            value = "info"
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          env {
            name  = "PORT"
            value = "5055"
          }

          port {
            container_port = 5055
            protocol       = "TCP"
          }

          // Configuration
          volume_mount {
            mount_path = "/app/config"
            name       = var.data_volume_name
          }
        }

        // Configuration
        volume {
          name = var.data_volume_name

          persistent_volume_claim {
            claim_name = var.data_volume_name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "overseerr" {
  metadata {
    name      = "overseerr"
    namespace = kubernetes_namespace.overseerr.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 5055
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "overseerr"
    }
  }
}

resource "kubernetes_ingress_v1" "overseerr" {
  metadata {
    name      = "overseerr"
    namespace = kubernetes_namespace.overseerr.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.overseerr_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "overseerr"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.overseerr_host]
      secret_name = "overseerr-ingress-cert"
    }
  }
}
