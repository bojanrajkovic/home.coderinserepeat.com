resource "kubernetes_namespace_v1" "transmission" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "airvpn_credentials" {
  depends_on = [kubernetes_namespace_v1.transmission]

  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = var.airvpn_credentials_secret
      namespace = kubernetes_namespace_v1.transmission.metadata[0].name
    }

    spec = {
      itemPath = var.airvpn_credentials_1password_vault_item_id
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "transmission_config" {
  depends_on = [kubernetes_namespace_v1.transmission]

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

resource "kubernetes_deployment_v1" "transmission" {
  depends_on = [
    kubernetes_manifest.airvpn_credentials,
    kubernetes_namespace_v1.transmission,
    kubernetes_persistent_volume_claim_v1.transmission_config
  ]

  metadata {
    name      = "transmission"
    namespace = kubernetes_namespace_v1.transmission.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "transmission"
      }
    }

    template {
      metadata {
        name      = "transmission"
        namespace = kubernetes_namespace_v1.transmission.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "transmission"
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
          image = "docker.io/qmcgaw/gluetun:v3.40.0@sha256:2b42bfa046757145a5155acece417b65b4443c8033fb88661a8e9dcf7fda5a00"

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
          name  = "transmission"
          image = "lscr.io/linuxserver/transmission:4.0.6@sha256:176de05ac125b6a7d781275419e54e02751c7e00620b0a45141cbf1ee6f7b65c"

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

          env {
            name  = "TRANSMISSION_WEB_HOME"
            value = "/config/flood-for-transmission"
          }

          port {
            container_port = 9091
            protocol       = "TCP"
          }

          # Configuration
          volume_mount {
            mount_path = "/config"
            name       = var.data_volume_name
          }

          volume_mount {
            mount_path = "/etc/localtime"
            name       = "localtime"
            read_only  = true
          }

          # Data
          dynamic "volume_mount" {
            for_each = var.host_volumes

            content {
              mount_path = "/data/${volume_mount.key}"
              name       = volume_mount.key
            }
          }
        }

        # Configuration
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

        # Data
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

resource "kubernetes_service_v1" "transmission" {
  metadata {
    name      = "transmission"
    namespace = kubernetes_namespace_v1.transmission.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 9091
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "transmission"
    }
  }
}

resource "kubernetes_ingress_v1" "transmission" {
  metadata {
    name      = "transmission"
    namespace = kubernetes_namespace_v1.transmission.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.transmission_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "transmission"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.transmission_host]
      secret_name = "transmission-ingress-cert"
    }
  }
}
