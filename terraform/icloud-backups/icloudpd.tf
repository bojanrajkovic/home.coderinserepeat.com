resource "kubernetes_namespace" "icloud_pd" {
  metadata {
    name = var.namespace_name
    labels = {
      "operator.1password.io/auto-restart" : true
    }
  }
}

resource "kubernetes_manifest" "icloud_credentials" {
  depends_on = [kubernetes_namespace.icloud_pd]
  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"
    metadata = {
      name      = var.icloud_password_secret
      namespace = kubernetes_namespace.icloud_pd.metadata[0].name
    }
    spec = {
      itemPath = var.icloud_password_1password_vault_item_id
    }
  }
}

resource "kubernetes_deployment_v1" "icloud_pd" {
  metadata {
    name      = "icloud-pd"
    namespace = kubernetes_namespace.icloud_pd.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "icloud-pd"
      }
    }

    template {
      metadata {
        name      = "icloud-pd"
        namespace = kubernetes_namespace.icloud_pd.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "icloud-pd"
        }
      }

      spec {
        container {
          name  = "icloud-pd"
          image = "docker.io/icloudpd/icloudpd:latest"
          stdin = true
          tty   = true

          args = [
            "icloudpd",
            "--directory", "/data/photos/iCloud",
            "--username", "brajkovic@coderinserepeat.com",
            "--watch-with-interval", "3600",
            "--auto-delete",
            "--align-raw", "original",
            "--no-progress-bar",
            # "--password", "$(ICLOUD_PASSWORD)"
            # "--mfa-provider", "webui"
          ]

          env {
            name = "ICLOUD_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.icloud_password_secret
                key  = "password"
              }
            }
          }

          env {
            name  = "TZ"
            value = "America/New_York"
          }

          volume_mount {
            mount_path = "/etc/localtime"
            name       = "localtime"
            read_only  = true
          }

          // Data
          dynamic "volume_mount" {
            for_each = var.icloud_pd_host_volumes

            content {
              mount_path = "/data/${volume_mount.key}"
              name       = volume_mount.key
            }
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
          for_each = var.icloud_pd_host_volumes

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
