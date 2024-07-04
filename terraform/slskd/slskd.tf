resource "kubernetes_namespace" "slskd" {
  metadata {
    name = var.namespace_name
    labels = {
      "operator.1password.io/auto-restart" : true
    }
  }
}

resource "kubernetes_manifest" "airvpn_credentials" {
  depends_on = [kubernetes_namespace.slskd]
  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"
    metadata = {
      name      = var.airvpn_credentials_secret
      namespace = kubernetes_namespace.slskd.metadata[0].name
    }
    spec = {
      itemPath = var.airvpn_credentials_1password_vault_item_id
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "slskd_config" {
  depends_on = [kubernetes_namespace.slskd]
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

resource "kubernetes_deployment_v1" "slskd" {
  depends_on = [
    kubernetes_manifest.airvpn_credentials,
    kubernetes_namespace.slskd,
    kubernetes_persistent_volume_claim_v1.slskd_config
  ]

  metadata {
    name      = "slskd"
    namespace = kubernetes_namespace.slskd.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "slskd"
      }
    }

    template {
      metadata {
        name      = "slskd"
        namespace = kubernetes_namespace.slskd.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "slskd"
        }
      }

      spec {
        dns_policy = "None"

        dns_config {
          nameservers = ["8.8.8.8", "1.1.1.1"]

          option {
            name  = "ndots"
            value = 1
          }

          option {
            name = "edns0"
          }
        }

        container {
          name  = "gluetun"
          image = "docker.io/qmcgaw/gluetun@sha256:3ef4b38852f3308fb4b9801975160168456f517853c3f2e9e9483e6aefb62065"

          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }
          }

          dynamic "env" {
            for_each = nonsensitive(keys(var.gluetun_configuration))

            content {
              name  = env.value
              value = var.gluetun_configuration[env.value]
            }
          }

          env {
            name = "WIREGUARD_PRIVATE_KEY"
            value_from {
              secret_key_ref {
                name = var.airvpn_credentials_secret
                key  = "password"
              }
            }
          }

          env {
            name = "WIREGUARD_PRESHARED_KEY"
            value_from {
              secret_key_ref {
                name = var.airvpn_credentials_secret
                key  = "username"
              }
            }
          }
        }

        container {
          name  = "slskd"
          image = "docker.io/slskd/slskd:0.21.1@sha256:e4bb957f69e2679e79db40e5e083804d1459eba4914cc0e2b6f241437172773e"

          port {
            container_port = 5030
            protocol       = "TCP"
          }

          // Configuration
          volume_mount {
            mount_path = "/app"
            name       = var.config_volume_name
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
          name = var.config_volume_name

          persistent_volume_claim {
            claim_name = var.config_volume_name
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

resource "kubernetes_service_v1" "slskd" {
  metadata {
    name      = "slskd"
    namespace = kubernetes_namespace.slskd.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 5030
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" : "slskd"
    }
  }
}

resource "kubernetes_ingress_v1" "slskd" {
  metadata {
    name      = "slskd"
    namespace = kubernetes_namespace.slskd.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = var.soulseek_host
      http {
        path {
          path = "/"
          backend {
            service {
              name = "slskd"
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
      hosts       = [var.soulseek_host]
      secret_name = "slskd-ingress-cert"
    }
  }
}
