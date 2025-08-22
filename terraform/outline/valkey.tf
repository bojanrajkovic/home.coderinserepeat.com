resource "kubernetes_deployment_v1" "valkey" {
  metadata {
    name      = "valkey"
    namespace = var.namespace_name

    labels = {
      "app.kubernetes.io/name"             = "valkey"
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
        "app.kubernetes.io/name" = "valkey"
      }
    }

    template {
      metadata {
        name      = "valkey"
        namespace = var.namespace_name

        labels = {
          "app.kubernetes.io/name" = "valkey"
        }
      }

      spec {
        container {
          name  = "valkey"
          image = "valkey/valkey:latest@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571"

          port {
            container_port = 6379
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "valkey_service" {
  metadata {
    name      = "valkey"
    namespace = var.namespace_name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "valkey"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}