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
  for_each   = var.pd_backup_apple_ids
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
          image = "docker.io/icloudpd/icloudpd:1.23.0@sha256:5fa9d556c18c18368a001fa78c2411d75dbe737ba47e94d608d92a99b3275b00"

          args = sensitive([
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
          ])

          port {
            container_port = 8080
            name           = "webui"
            protocol       = "TCP"
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
            name       = var.data_volume_name
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

resource "kubernetes_service_v1" "icloud_pd" {
  for_each = var.pd_backup_apple_ids

  metadata {
    name      = "icloud-pd-${each.key}"
    namespace = kubernetes_namespace.icloud_pd.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      name        = "webui"
      port        = 8080
      protocol    = "TCP"
      target_port = "webui"
    }

    selector = {
      "app.kubernetes.io/name" = "icloud-pd-${each.key}"
    }
  }
}

resource "kubernetes_ingress_v1" "icloud_pd" {
  depends_on = [kubernetes_namespace.icloud_pd, kubernetes_service_v1.icloud_pd]

  metadata {
    name      = "icloud-pd"
    namespace = kubernetes_namespace.icloud_pd.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    dynamic "rule" {
      for_each = var.pd_backup_apple_ids
      iterator = id

      content {
        host = "${id.key}.${var.icloudpd_host}"

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = "icloud-pd-${id.key}"

                port {
                  number = 8080
                }
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [for key, value in var.pd_backup_apple_ids : "${key}.${var.icloudpd_host}"]
      secret_name = "icloud-pd-ingress-cert"
    }
  }
}
