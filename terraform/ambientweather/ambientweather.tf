resource "kubernetes_namespace" "ambientweather" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

data "kubernetes_secret_v1" "postgres_credentials" {
  metadata {
    name      = "healthchecks-cluster-app"
    namespace = var.namespace_name
  }
}

resource "kubernetes_deployment_v1" "ambientweather" {
  metadata {
    name      = "ambientweather"
    namespace = kubernetes_namespace.ambientweather.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "ambientweather"
      }
    }

    template {
      metadata {
        name      = "ambientweather"
        namespace = kubernetes_namespace.ambientweather.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "ambientweather"
        }
      }

      spec {
        container {
          name  = "ambientweather"
          image = "ghcr.io/neilenns/ambientweather2mqtt:latest@sha256:d37f8c46067c7ca4fcdfe9e200c8577b7723d5d9b8482730bb13459219d807ff"

          port {
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name  = "STATION_MAC_ADDRESS"
            value = var.station_mac_address
          }

          env {
            name  = "MQTT_SERVER"
            value = var.mqtt_server
          }

          env {
            name  = "MQTT_USERNAME"
            value = var.mqtt_username
          }

          env {
            name  = "MQTT_PASSWORD"
            value = var.mqtt_password
          }

          env {
            name = "TZ"
            value = "America/New_York"
          }

          env {
            name = "LOCALE"
            value = "en-US"
          }

          env {
            name = "LOG_LEVEL"
            value = "debug"
          }

          env {
            name = "MQTT_REJECT_UNAUTHORIZED"
            value = "false"
          }

          env {
            name = "PORT"
            value = "8080"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "ambientweather" {
  metadata {
    name      = "ambientweather"
    namespace = kubernetes_namespace.ambientweather.metadata[0].name
  }

  spec {
    type                    = "ClusterIP"
    internal_traffic_policy = "Cluster"
    ip_families             = ["IPv4"]
    ip_family_policy        = "SingleStack"

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "ambientweather"
    }
  }
}

resource "kubernetes_ingress_v1" "ambientweather" {
  metadata {
    name      = "ambientweather"
    namespace = kubernetes_namespace.ambientweather.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.ambientweather_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "ambientweather"

              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
