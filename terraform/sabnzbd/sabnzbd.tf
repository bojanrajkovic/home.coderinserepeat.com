resource "kubernetes_namespace_v1" "sabnzbd" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "airvpn_credentials" {
  depends_on = [kubernetes_namespace_v1.sabnzbd]

  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = var.airvpn_credentials_secret
      namespace = kubernetes_namespace_v1.sabnzbd.metadata[0].name
    }

    spec = {
      itemPath = var.airvpn_credentials_1password_vault_item_id
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "sabnzbd_config" {
  depends_on = [kubernetes_namespace_v1.sabnzbd]

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

resource "kubernetes_deployment_v1" "sabnzbd" {
  depends_on = [
    kubernetes_manifest.airvpn_credentials,
    kubernetes_namespace_v1.sabnzbd,
    kubernetes_persistent_volume_claim_v1.sabnzbd_config
  ]

  metadata {
    name      = "sabnzbd"
    namespace = kubernetes_namespace_v1.sabnzbd.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "sabnzbd"
      }
    }

    template {
      metadata {
        name      = "sabnzbd"
        namespace = kubernetes_namespace_v1.sabnzbd.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "sabnzbd"
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
          name  = "sabnzbd"
          image = "lscr.io/linuxserver/sabnzbd:latest@sha256:9011bb04b95417fe6345e48c98f9880188f5825402623a0201d29d1c300eea67"

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
            container_port = 8080
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

resource "kubernetes_service_v1" "sabnzbd" {
  metadata {
    name      = "sabnzbd"
    namespace = kubernetes_namespace_v1.sabnzbd.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "sabnzbd"
    }
  }
}

resource "kubernetes_ingress_v1" "sabnzbd" {
  metadata {
    name      = "sabnzbd"
    namespace = kubernetes_namespace_v1.sabnzbd.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.sabnzbd_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "sabnzbd"

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.sabnzbd_host]
      secret_name = "sabnzbd-ingress-cert"
    }
  }
}
