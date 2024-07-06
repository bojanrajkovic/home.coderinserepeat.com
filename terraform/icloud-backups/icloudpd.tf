data "terraform_remote_state" "ses" {
  backend = "s3"

  config = {
    bucket = "rajkovic-homelab-tf-state"
    key    = "aws/ses.tfstate"
    region = "us-east-1"
  }
}

resource "kubernetes_namespace" "icloud_pd" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "icloud_auth" {
  for_each = var.pd_backup_apple_ids
  depends_on = [kubernetes_namespace.icloud_pd]

  metadata {
    name      = "${var.data_volume_name}-${each.key}"
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

resource "kubernetes_deployment_v1" "icloud_pd" {
  for_each = var.pd_backup_apple_ids

  metadata {
    name      = "icloud-pd-${each.key}"
    namespace = kubernetes_namespace.icloud_pd.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "icloud-pd-${each.key}"
      }
    }

    template {
      metadata {
        name      = "icloud-pd-${each.key}"
        namespace = kubernetes_namespace.icloud_pd.metadata[0].name

        labels = {
          "app.kubernetes.io/name" = "icloud-pd-${each.key}"
        }
      }

      spec {
        container {
          name  = "icloud-pd"
          image = "docker.io/icloudpd/icloudpd:1.21.0@sha256:87b69bbadf8434505ccd74d871f4404abb07e571d6e95a85f2a3aa7787044376"

          args = [
            "icloudpd",
            "--directory", "/data/photos/iCloud (${title(each.key)})",
            "--username", "${each.value}",
            "--watch-with-interval", "3600",
            "--auto-delete",
            "--align-raw", "original",
            "--no-progress-bar",
            "--password-provider", "webui",
            "--mfa-provider", "webui",
            "--smtp-username", data.terraform_remote_state.ses.outputs.smtp_username["icloudpd"],
            "--smtp-password", data.terraform_remote_state.ses.outputs.smtp_password["icloudpd"],
            "--smtp-host", "email-smtp.us-east-1.amazonaws.com",
            "--notification-email", var.pd_backup_apple_ids["bojan"],
            "--notification-email-from", data.terraform_remote_state.ses.outputs.sender_emails["icloudpd"],
            "--cookie-directory", "/auth"
          ]

          port {
            container_port = 8080
            name = "webui"
            protocol = "TCP"
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

          volume_mount {
            mount_path = "/auth"
            name = var.data_volume_name
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
          name = var.data_volume_name

          persistent_volume_claim {
            claim_name = "${var.data_volume_name}-${each.key}"
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
