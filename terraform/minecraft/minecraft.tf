resource "kubernetes_namespace_v1" "minecraft" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "minecraft_data" {
  depends_on = [kubernetes_namespace_v1.minecraft]

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

resource "kubernetes_deployment_v1" "minecraft" {
  depends_on = [kubernetes_persistent_volume_claim_v1.minecraft_data]

  metadata {
    name      = "minecraft"
    namespace = var.namespace_name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "minecraft"
      }
    }

    template {
      metadata {
        name      = "minecraft"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "minecraft"
        }
      }

      spec {
        container {
          image = "itzg/minecraft-bedrock-server@sha256:23bec2e1f71591d9e1635b5d3c9b3af5fb671548d5576e7876989dd5c3433054"
          name  = "minecraft"

          port {
            name           = "server"
            container_port = 19132
            protocol       = "UDP"
          }

          volume_mount {
            mount_path = "/data"
            name       = var.data_volume_name
          }

          env {
            name  = "EULA"
            value = "TRUE"
          }

          env {
            name  = "SERVER_NAME"
            value = "Rajkovic Family Server"
          }

          env {
            name  = "ALLOW_CHEATS"
            value = "true"
          }

          env {
            name  = "ONLINE_MODE"
            value = "false"
          }

          env {
            name  = "LEVEL_TYPE"
            value = "DEFAULT"
          }

          env {
            name  = "SERVER_AUTHORITATIVE_MOVEMENT"
            value = "server-auth-with-rewind"
          }

          env {
            name  = "CORRECT_PLAYER_MOVEMENT"
            value = "true"
          }

          env {
            name  = "OPS"
            value = "2533274880326726"
          }

          env {
            name  = "DIFFICULTY"
            value = "easy"
          }

          env {
            name  = "LEVEL_SEED"
            value = "2171425265347214990"
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

resource "kubernetes_service_v1" "minecraft" {
  depends_on = [kubernetes_namespace_v1.minecraft]

  metadata {
    name      = "minecraft-srv"
    namespace = var.namespace_name

    annotations = {
      "external-dns.alpha.kubernetes.io/hostname"  = var.minecraft_host
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-address-pool"
      "metallb.io/ip-allocated-from-pool"          = "metallb-address-pool"
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "server"
      port        = 19132
      protocol    = "UDP"
      target_port = "server"
    }

    selector = {
      "app.kubernetes.io/name" = "minecraft"
    }
  }
}
