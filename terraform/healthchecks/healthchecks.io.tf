resource "kubernetes_namespace" "healthchecks_io" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "healthchecks_io" {
  depends_on = [kubernetes_namespace.healthchecks_io]

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

resource "kubernetes_deployment_v1" "healthchecks_io" {
  metadata {
    name      = "healthchecks-io"
    namespace = kubernetes_namespace.healthchecks_io.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "healthchecks-io"
      }
    }

    template {
      metadata {
        name      = "healthchecks-io"
        namespace = kubernetes_namespace.healthchecks_io.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "healthchecks-io"
        }
      }

      spec {
        security_context {
          fs_group               = 999
          fs_group_change_policy = "Always"
        }

        init_container {
          name  = "fix-data-dir-ownership"
          image = "alpine:3@sha256:1e42bbe2508154c9126d48c2b8a75420c3544343bf86fd041fb7527e017a4b4a"

          command = [
            "chown",
            "-R",
            "999:999",
            "/data"
          ]

          volume_mount {
            name       = var.data_volume_name
            mount_path = "/data"
          }
        }

        container {
          name  = "healthchecks-io"
          image = "healthchecks/healthchecks:v3.7@sha256:b28daa5446b46add2e6b4e307a00919c9373441dfbb42a91531abb35cb595e23"

          env {
            name  = "ALLOWED_HOSTS"
            value = var.healthchecks_host
          }

          env {
            name  = "SITE_ROOT"
            value = "https://${var.healthchecks_host}"
          }

          env {
            name  = "PUSHOVER_API_TOKEN"
            value = var.pushover_api_key
          }

          env {
            name  = "REGISTRATION_OPEN"
            value = "False"
          }

          env {
            name  = "RP_ID"
            value = var.healthchecks_host
          }

          env {
            name  = "PUSHOVER_SUBSCRIPTION_URL"
            value = var.pushover_subscription_url
          }

          env {
            name  = "DB"
            value = "sqlite"
          }

          env {
            name  = "DB_NAME"
            value = "/data/hc.sqlite"
          }

          port {
            container_port = 8000
            protocol       = "TCP"
          }

          // Configuration
          volume_mount {
            mount_path = "/data"
            name       = var.data_volume_name
          }

          volume_mount {
            mount_path = "/etc/localtime"
            name       = "localtime"
            read_only  = true
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
      }
    }
  }
}

resource "kubernetes_service_v1" "healthchecks_io" {
  metadata {
    name      = "healthchecks-io"
    namespace = kubernetes_namespace.healthchecks_io.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "healthchecks-io"
    }
  }
}

resource "kubernetes_ingress_v1" "healthchecks_io" {
  metadata {
    name      = "healthchecks-io"
    namespace = kubernetes_namespace.healthchecks_io.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.healthchecks_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "healthchecks-io"

              port {
                number = 8000
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.healthchecks_host]
      secret_name = "healthchecks-io-ingress-cert"
    }
  }
}
