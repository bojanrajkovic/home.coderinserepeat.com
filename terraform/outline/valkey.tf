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
          image = "valkey/valkey:latest"

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