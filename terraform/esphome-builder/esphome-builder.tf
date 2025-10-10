# Builder namespace
resource "kubernetes_namespace_v1" "esphome_builder" {
  metadata {
    name = var.builder_namespace

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

# Target namespace where ESPHome upload pods will be created
resource "kubernetes_namespace_v1" "esphome" {
  metadata {
    name = var.target_namespace

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

# ServiceAccount for the builder
resource "kubernetes_service_account_v1" "esphome_builder" {
  metadata {
    name      = "esphome-builder"
    namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name
  }
}

# Role in target namespace with permissions to create ConfigMaps and Pods
resource "kubernetes_role_v1" "esphome_builder" {
  metadata {
    name      = "esphome-builder"
    namespace = kubernetes_namespace_v1.esphome.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "list", "update", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get"]
  }
}

# RoleBinding to give the ServiceAccount permissions in target namespace
resource "kubernetes_role_binding_v1" "esphome_builder" {
  metadata {
    name      = "esphome-builder"
    namespace = kubernetes_namespace_v1.esphome.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.esphome_builder.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.esphome_builder.metadata[0].name
    namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name
  }
}

# OnePasswordItem for GitHub token
resource "kubernetes_manifest" "github_token" {
  depends_on = [kubernetes_namespace_v1.esphome_builder]

  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = "github-token"
      namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name
    }

    spec = {
      itemPath = var.github_token_1password_vault_item_id
    }
  }
}

# PVC for git repository storage
resource "kubernetes_persistent_volume_claim_v1" "esphome_builder_data" {
  metadata {
    name      = "esphome-builder-data"
    namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name
  }

  spec {
    storage_class_name = "zfs-durable"
    access_modes       = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.esphome_builder]
}

# ConfigMap containing the builder configuration
resource "kubernetes_config_map_v1" "esphome_builder_config" {
  metadata {
    name      = "esphome-builder-config"
    namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name
  }

  data = {
    "config.yaml" = yamlencode({
      github = {
        repo      = var.github_repo
        token     = "file:///var/secrets/token"
        branch    = var.github_branch
        clone_dir = "/data/repos"
      }

      watcher = {
        poll_interval = var.poll_interval
        paths         = var.watch_paths
      }

      kubernetes = {
        namespace     = var.target_namespace
        esphome_image = var.esphome_image
      }

      log_level = var.log_level
    })
  }

  depends_on = [kubernetes_namespace_v1.esphome_builder]
}

# Deployment for the esphome-fanout-builder
resource "kubernetes_deployment_v1" "esphome_builder" {
  metadata {
    name      = "esphome-builder"
    namespace = kubernetes_namespace_v1.esphome_builder.metadata[0].name

    labels = {
      app = "esphome-builder"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "esphome-builder"
      }
    }

    template {
      metadata {
        labels = {
          app = "esphome-builder"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.esphome_builder.metadata[0].name

        security_context {
          fs_group = 65534
        }

        container {
          name  = "builder"
          image = var.builder_image

          args = [
            "-config",
            "/config/config.yaml"
          ]

          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }

          volume_mount {
            name       = "github-token"
            mount_path = "/var/secrets"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }

            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.esphome_builder_config.metadata[0].name
          }
        }

        volume {
          name = "github-token"

          secret {
            secret_name = kubernetes_manifest.github_token.manifest.metadata.name
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.esphome_builder_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map_v1.esphome_builder_config,
    kubernetes_manifest.github_token,
    kubernetes_role_binding_v1.esphome_builder,
    kubernetes_persistent_volume_claim_v1.esphome_builder_data
  ]
}
