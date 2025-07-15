locals {
  env_map = tomap({
    NODE_ENV                               = "production",
    SECRET_KEY                             = var.secret_key,
    UTILS_SECRET                           = var.utils_key,
    DATABASE_URL                           = data.kubernetes_secret_v1.postgres_credentials.data["uri"],
    PGSSLMODE                              = "disable",
    REDIS_URL                              = "redis://valkey:6379",
    URL                                    = "https://outline.services.coderinserepeat.com",
    FORCE_HTTPS                            = false,
    GOOGLE_CLIENT_ID                       = var.google_client_id,
    GOOGLE_CLIENT_SECRET                   = var.google_client_secret,
    FILE_STORAGE                           = "local",
    FILE_STORAGE_UPLOAD_MAX_SIZE           = 26214400,
    FILE_STORAGE_IMPORT_MAX_SIZE           = 26214400,
    FILE_STORAGE_WORKSPACE_IMPORT_MAX_SIZE = 26214400
  })
}

data "kubernetes_secret_v1" "postgres_credentials" {
  metadata {
    name      = "outline-cluster-app"
    namespace = var.namespace_name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "outline_data" {
  depends_on = [kubernetes_namespace_v1.outline]

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

resource "kubernetes_deployment_v1" "outline" {
  metadata {
    name      = "outline"
    namespace = var.namespace_name

    labels = {
      "app.kubernetes.io/name"             = "outline"
      "operator.1password.io/auto-restart" = true
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "outline"
      }
    }

    template {
      metadata {
        name      = "outline"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "outline"
        }
      }

      spec {
        security_context {
          fs_group               = 1001
          fs_group_change_policy = "Always"
        }

        init_container {
          name  = "fix-data-dir-ownership"
          image = "alpine:3@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1"

          command = [
            "chown",
            "-R",
            "1001:1001",
            "/var/lib/outline/data"
          ]

          volume_mount {
            name       = var.data_volume_name
            mount_path = "/var/lib/outline/data"
          }
        }

        container {
          name  = "outline"
          image = "docker.getoutline.com/outlinewiki/outline:latest"

          port {
            container_port = 3000
            protocol       = "TCP"
          }

          volume_mount {
            mount_path = "/var/lib/outline/data"
            name       = var.data_volume_name
          }

          dynamic "env" {
            for_each = local.env_map

            content {
              name  = env.key
              value = env.value
            }
          }
        }

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

resource "kubernetes_service_v1" "outline" {
  metadata {
    name      = "outline"
    namespace = var.namespace_name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "outline"
    }
  }
}

resource "kubernetes_ingress_v1" "outline" {
  metadata {
    name      = "outline"
    namespace = var.namespace_name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.outline_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.outline.metadata[0].name

              port {
                number = 3000
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.outline_host]
      secret_name = "outline-ingress-cert"
    }
  }
}